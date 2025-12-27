# NovaDoom RCON Integration Guide

This document describes how to integrate RCON (Remote Console) support into the NovaDoom platform for managing game servers.

---

## Overview

RCON allows the NovaDoom platform to send administrative commands to running game servers. Commands are executed with server-side privileges, enabling full remote management without direct server access.

---

## 1. Network Protocol

### Connection Details

| Setting | Value |
|---------|-------|
| Protocol | UDP |
| Default Port | 10666 (configurable per server) |
| Max Packet Size | 8192 bytes |
| Safe Packet Size | 1200 bytes |

### Message Types (Client-to-Server)

```
clc_rcon          (0x09) - Command execution message
clc_rcon_password (0x0A) - Authentication message
```

### Message Types (Server-to-Client)

```
svc_consoleplayer (0x0B) - Initial connection response (contains digest)
svc_print         (0x15) - Command output response
```

---

## 2. Authentication Flow

RCON uses a challenge-response authentication mechanism. **The digest is delivered automatically when a client connects to the server via the `svc_consoleplayer` message.**

```
┌─────────────────┐                      ┌─────────────────┐
│  NovaDoom API   │                      │   Game Server   │
└────────┬────────┘                      └────────┬────────┘
         │                                        │
         │  1. Send connection request            │
         │     (PROTO_CHALLENGE + token + info)   │
         │ ──────────────────────────────────────>│
         │                                        │
         │  2. Server responds with               │
         │     svc_consoleplayer message          │
         │     containing player_id + digest      │
         │ <──────────────────────────────────────│
         │     (digest is 32-char MD5 hex string) │
         │                                        │
         │  3. Send RCON login request            │
         │     clc_rcon_password (0x0A)           │
         │     login=1                            │
         │     challenge=MD5(password + digest)   │
         │ ──────────────────────────────────────>│
         │                                        │
         │  4. Server validates                   │
         │     MD5(rcon_password + client_digest) │
         │     == challenge                       │
         │                                        │
         │  5. Auth success (no explicit response │
         │     unless failure - "Bad password")   │
         │                                        │
         │  6. Send RCON command                  │
         │     clc_rcon (0x09) + command_string   │
         │ ──────────────────────────────────────>│
         │                                        │
         │  7. Command output via svc_print       │
         │ <──────────────────────────────────────│
         │                                        │
```

### Digest Generation (Server-side)

The server generates a unique digest per client connection:

```
digest = MD5(timestamp + level.time + VERSION + client_IP)
```

### Password Verification

```python
# Platform sends:
challenge = MD5(rcon_password + server_digest)

# Server verifies:
expected = MD5(rcon_password + client_digest)
if challenge == expected:
    allow_rcon = True
```

### How to Receive the Digest (Critical for Platform Integration)

The digest is **only sent once** during the initial connection handshake. The platform must:

1. **Connect as a game client** by sending a connection packet with `PROTO_CHALLENGE` (-5560020)
2. **Parse the `svc_consoleplayer` response** to extract the digest
3. **Store the digest** for the duration of the session

**Source code references:**
- Server generates digest: `server/src/sv_main.cpp:1815`
- Server sends digest: `server/src/sv_main.cpp:1874`
- Client receives digest: `client/src/cl_parse.cpp:924`
- Client stores digest: `client/src/cl_main.cpp:122`

**Digest characteristics:**
- 32-character lowercase hexadecimal string (MD5 hash)
- Unique per connection (changes if client reconnects)
- Generated from: `MD5(unix_timestamp + level.time + VERSION + client_IP)`

### Step 1: Get Server Token (Launcher Query)

Before connecting, you must first query the server to get a valid `server_token`. Send a launcher challenge:

```
Offset  Size    Field               Value
──────────────────────────────────────────────────────────────
0       4       challenge           LAUNCHER_CHALLENGE (777123, int32 LE)
```

**Server responds with:**
```
Offset  Size    Field               Description
──────────────────────────────────────────────────────────────
0       4       challenge           MSG_CHALLENGE (5560020)
4       4       server_token        Token to use in connection packet (int32 LE)
8       ...     hostname            Server hostname (null-terminated)
...     1       players             Current player count
...     1       max_players         Max players
...     ...     mapname             Current map (null-terminated)
...     ...     wad_info            WAD file information
```

The `server_token` is required for connection. Tokens are tied to your IP address and expire after a short time.

**Source:** `server/src/sv_sqpold.cpp:141` (SV_SendServerInfo)

### Step 2: Connection Packet Format (Required to Receive Digest)

The initial connection packet must be sent to receive the digest. Format from `client/src/cl_main.cpp:1863-1884`:

```
Offset  Size    Field               Value/Description
──────────────────────────────────────────────────────────────
0       4       challenge           PROTO_CHALLENGE (-5560020, signed int32 LE)
4       4       server_token        Token from launcher query (int32 LE, use 0 for direct connect)
8       2       version             Protocol version (65, int16 LE)
10      1       connection_type     0x00 = play, 0x01 = spectate, etc.
11      4       game_version        GAMEVER (e.g., 0x000A0003 for 10.3.0, int32 LE)
15      ...     userinfo            clc_userinfo message (see below)
...     4       rate                Deprecated, send 0xFFFF (int32 LE)
...     ...     password_hash       MD5 of join_password if server is passworded (null-terminated)
```

**Userinfo format (clc_userinfo = 0x05):**
```
Offset  Size    Field               Description
──────────────────────────────────────────────────────────────
0       1       marker              0x05 (clc_userinfo)
1       ...     netname             Player name (null-terminated string)
...     1       team                Team number (byte)
...     4       gender              Gender setting (int32 LE)
...     4       color               RGBA color (4 bytes)
...     ...     skin                Skin name (null-terminated, send empty "")
...     4       aimdist             Aim distance (int32 LE)
...     1       unlag               Deprecated, send 0x01 (bool)
...     1       predict_weapons     Weapon prediction (bool)
...     1       switchweapon        Weapon switch mode (byte)
...     9       weapon_prefs        Weapon preference order (9 bytes)
```

**Example connection packet (hex):**
```
EC AB AB FF    # PROTO_CHALLENGE (-5560020 as signed int32 LE)
00 00 00 00    # server_token (0 for direct connect)
41 00          # version (65 as int16 LE)
00             # connection_type (0 = play)
03 00 0A 00    # game_version (10.3.0)
05             # clc_userinfo marker
52 43 4F 4E 00 # netname "RCON\0"
00             # team (0)
00 00 00 00    # gender (0)
00 00 00 FF    # color (black with full alpha)
00             # skin (empty string)
00 00 00 00    # aimdist (0)
01             # unlag (true)
01             # predict_weapons (true)
00             # switchweapon (0)
01 02 03 04 05 06 07 08 09  # weapon_prefs
FF FF FF FF    # rate (deprecated, max value)
00             # password_hash (empty = no password)
```

---

## 3. Packet Format

**Important:** NovaDoom uses Protocol Buffers for message serialization. Messages are prefixed with a varint-encoded length followed by the protobuf payload.

### Digest Delivery Packet (svc_consoleplayer)

The server sends this packet immediately after successful connection. **This is how the platform receives the digest needed for RCON authentication.**

```
Byte   Field         Description
─────────────────────────────────────────
0      marker        0x0B (svc_consoleplayer)
1+     length        Varint-encoded protobuf message length
...    protobuf      ConsolePlayer message:
                       - pid (int32): Player ID assigned by server
                       - digest (string): 32-char MD5 hex string for RCON auth
```

**Protobuf Definition (from `odaproto/server.proto`):**
```protobuf
// svc_consoleplayer
message ConsolePlayer {
    int32 pid = 1;
    string digest = 2;
}
```

### Login Packet (clc_rcon_password)

```
Byte   Field         Description
─────────────────────────────────────────
0      marker        0x0A (clc_rcon_password)
1      login         0x01 (login) or 0x00 (logout)
2+     challenge     MD5 hash string (null-terminated)
```

### Command Packet (clc_rcon)

```
Byte   Field         Description
─────────────────────────────────────────
0      marker        0x09 (clc_rcon)
1+     command       Command string (null-terminated)
```

### Response Packet (svc_print)

```
Byte   Field         Description
─────────────────────────────────────────
0      marker        0x15 (svc_print)
1+     length        Varint-encoded protobuf message length
...    protobuf      Print message:
                       - level (int32): Print level (2=HIGH, 4=CHAT, etc.)
                       - message (string): Response text
```

---

## 4. Server Configuration

### Required Server CVAR

```
rcon_password "your_secure_password"
```

- Minimum 5 characters
- Set in server config or via command line
- Empty string disables RCON

---

## 5. Available RCON Commands

### Player Management

| Command | Arguments | Description |
|---------|-----------|-------------|
| `kick` | `<player_id> [reason]` | Kick player from server |
| `ban` | `<player_id> [duration] [reason]` | Ban player (duration: "2 hours", "permanent") |
| `forcespec` | `<player_id>` | Force player to spectator |
| `playerlist` | - | List all connected players with IDs |
| `players` | - | Alias for playerlist |
| `playerinfo` | `[player_id]` | Detailed player information |

**Example:**
```
kick 3 AFK too long
ban 5 1 hour Teamkilling
forcespec 2
```

### Map Management

| Command | Arguments | Description |
|---------|-----------|-------------|
| `map` | `<map_name>` | Change to specific map |
| `nextmap` | - | Advance to next map in rotation |
| `forcenextmap` | - | Force next map immediately |
| `restart` | - | Restart current map |
| `gotomap` | `<index\|name>` | Jump to map by index or name |
| `randmap` | - | Load random map from maplist |
| `maplist` | `[query]` | Show map rotation |
| `addmap` | `<map> [wads...]` | Add map to rotation |
| `delmap` | `<index>` | Remove map from rotation |
| `clearmaplist` | - | Clear entire map rotation |

**Example:**
```
map MAP01
addmap MAP07 plutonia.wad
gotomap 5
```

### Ban Management

| Command | Arguments | Description |
|---------|-----------|-------------|
| `addban` | `<ip> [duration] [name] [reason]` | Ban IP address |
| `delban` | `<index>` | Remove ban by index |
| `banlist` | - | List all active bans |
| `clearbanlist` | - | Remove all bans |
| `addexception` | `<ip> [duration] [name] [reason]` | Add ban exception |
| `delexception` | `<index>` | Remove exception |
| `exceptionlist` | - | List all exceptions |
| `savebanlist` | - | Save banlist to disk |
| `loadbanlist` | - | Reload banlist from disk |

**IP Wildcards supported:** `192.168.*.*`

**Example:**
```
addban 192.168.1.100 permanent Cheater Known cheater
banlist
```

### Game Settings (CVARs)

| CVAR | Type | Description |
|------|------|-------------|
| `sv_hostname` | string | Server display name |
| `sv_motd` | string | Message of the day |
| `sv_maxclients` | int | Maximum connections (2-255) |
| `sv_maxplayers` | int | Maximum active players (2-255) |
| `sv_fraglimit` | int | Frag limit (0=unlimited) |
| `sv_timelimit` | int | Time limit in minutes (0=unlimited) |
| `sv_scorelimit` | int | Score limit for team modes |
| `sv_allowcheats` | bool | Enable cheat commands |
| `sv_allowjump` | bool | Allow jumping |
| `sv_freelook` | bool | Allow mouselook |
| `sv_infiniteammo` | bool | Infinite ammunition |
| `sv_friendlyfire` | bool | Team damage enabled |
| `sv_fastmonsters` | bool | Fast monster mode |

**Setting CVARs:**
```
sv_fraglimit 50
sv_timelimit 20
sv_hostname "NovaDoom Official #1"
```

### Voting Configuration

| CVAR | Type | Description |
|------|------|-------------|
| `sv_vote_majority` | float | Vote pass ratio (0.0-1.0, default: 0.5) |
| `sv_vote_timelimit` | int | Vote duration in seconds |
| `sv_vote_timeout` | int | Cooldown between votes |
| `sv_callvote_kick` | bool | Allow kick votes |
| `sv_callvote_map` | bool | Allow map votes |
| `sv_callvote_fraglimit` | bool | Allow fraglimit votes |
| `sv_callvote_timelimit` | bool | Allow timelimit votes |

### CTF Settings

| CVAR | Type | Description |
|------|------|-------------|
| `ctf_manualreturn` | bool | Flags must be touched to return |
| `ctf_flagathometoscore` | bool | Own flag must be home to score |
| `ctf_flagtimeout` | int | Dropped flag return time (seconds) |

### Server Control

| Command | Description |
|---------|-------------|
| `say <message>` | Broadcast message to all players |
| `pause` | Pause/unpause game |
| `coinflip` | Random coin flip result |
| `savecfg` | Save server configuration |
| `quit` / `exit` | Shutdown server gracefully |
| `rquit` | Shutdown with reconnect signal |

### Pickup/Draft Commands

| Command | Arguments | Description |
|---------|-----------|-------------|
| `randpickup` | `[count]` | Random player selection |
| `randcaps` | - | Random captain selection (2 players) |

---

## 6. Platform Integration Examples

### Python Implementation

```python
import socket
import hashlib
import struct

class NovaDoomRCON:
    """
    RCON client for NovaDoom game servers.

    Important: This client must connect as a regular game client first to
    receive the digest from the server via svc_consoleplayer message.
    The digest is required for RCON authentication.
    """

    # Client-to-Server message types (from common/i_net.h)
    CLC_RCON = 0x09
    CLC_RCON_PASSWORD = 0x0A

    # Server-to-Client message types
    SVC_CONSOLEPLAYER = 0x0B
    SVC_PRINT = 0x15

    # Connection constants
    PROTO_CHALLENGE = -5560020
    VERSION = 65

    def __init__(self, host: str, port: int, password: str):
        self.host = host
        self.port = port
        self.password = password
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.socket.settimeout(5.0)
        self.digest = None
        self.player_id = None
        self.authenticated = False

    def _md5(self, data: str) -> str:
        """Calculate MD5 hash."""
        return hashlib.md5(data.encode()).hexdigest()

    def _read_varint(self, data: bytes, offset: int) -> tuple[int, int]:
        """Read a varint from bytes, return (value, new_offset)."""
        result = 0
        shift = 0
        while True:
            if offset >= len(data):
                raise ValueError("Incomplete varint")
            byte = data[offset]
            offset += 1
            result |= (byte & 0x7F) << shift
            if not (byte & 0x80):
                break
            shift += 7
        return result, offset

    def connect_and_get_digest(self) -> str:
        """
        Connect to server and extract digest from svc_consoleplayer response.

        Returns the digest string needed for RCON authentication.

        Note: Full connection requires sending userinfo and handling the
        complete handshake. This is a simplified example - the platform
        should implement the full connection protocol.
        """
        # The digest is sent in the svc_consoleplayer message after
        # successful connection. The full connection protocol involves:
        # 1. Send PROTO_CHALLENGE + token + version + userinfo
        # 2. Receive svc_consoleplayer with player_id and digest
        # 3. Receive additional game state messages

        # For platform integration, you need to:
        # - Parse incoming packets for svc_consoleplayer (0x0B)
        # - Extract the protobuf ConsolePlayer message
        # - The digest field contains the 32-char MD5 hex string

        raise NotImplementedError(
            "Full connection protocol required. "
            "See server/src/sv_main.cpp:SV_ConnectClient() for details."
        )

    def authenticate(self, server_digest: str) -> bool:
        """
        Authenticate with RCON password using server-provided digest.

        Args:
            server_digest: The 32-char MD5 hex string from svc_consoleplayer

        Returns:
            True if authentication successful (no "Bad password" response)
        """
        self.digest = server_digest
        challenge = self._md5(self.password + server_digest)

        # Build login packet: marker + login_flag + challenge_string
        packet = bytes([self.CLC_RCON_PASSWORD, 0x01])  # login=true
        packet += challenge.encode() + b'\x00'

        self.socket.sendto(packet, (self.host, self.port))

        # Server only responds on failure with "Bad password" message
        # No response typically means success
        try:
            response, _ = self.socket.recvfrom(8192)
            # Check if response contains error
            if b"Bad password" in response:
                return False
            self.authenticated = True
            return True
        except socket.timeout:
            # Timeout usually means success (no error response)
            self.authenticated = True
            return True

    def send_command(self, command: str) -> str:
        """Send RCON command and receive response."""
        if not self.authenticated:
            raise Exception("Not authenticated - call authenticate() first")

        # Build command packet: marker + command_string
        packet = bytes([self.CLC_RCON])
        packet += command.encode() + b'\x00'

        self.socket.sendto(packet, (self.host, self.port))

        # Collect responses (commands may generate multiple print messages)
        responses = []
        try:
            while True:
                data, _ = self.socket.recvfrom(8192)
                parsed = self._parse_response(data)
                if parsed:
                    responses.append(parsed)
        except socket.timeout:
            pass

        return '\n'.join(responses)

    def _parse_response(self, data: bytes) -> str:
        """
        Parse server response packet.

        Server responses use protobuf encoding. The svc_print message
        contains the command output.
        """
        if len(data) < 5:  # minimum: 4-byte sequence + 1-byte flags
            return ""

        # Skip 4-byte sequence number and 1-byte flags
        offset = 5

        while offset < len(data):
            if data[offset] == self.SVC_PRINT:
                offset += 1
                # Read varint length
                length, offset = self._read_varint(data, offset)
                # Extract protobuf message (simplified - just get the string)
                proto_data = data[offset:offset + length]
                # The message field is typically the last field in Print proto
                # This is a simplified extraction - use proper protobuf parsing
                # for production code
                try:
                    text = proto_data.decode('utf-8', errors='ignore')
                    # Filter out non-printable characters
                    return ''.join(c for c in text if c.isprintable() or c in '\n\r\t')
                except:
                    pass
                offset += length
            else:
                # Skip other message types
                break

        return ""

    def logout(self):
        """Logout from RCON session."""
        packet = bytes([self.CLC_RCON_PASSWORD, 0x00])  # login=false
        packet += b'\x00'
        self.socket.sendto(packet, (self.host, self.port))
        self.authenticated = False

    def close(self):
        """Close connection."""
        if self.authenticated:
            self.logout()
        self.socket.close()


# Usage example
# Note: In practice, you need to connect as a game client first
# to receive the digest from svc_consoleplayer

rcon = NovaDoomRCON("game1.novadoom.com", 10666, "secretpassword")

# The digest comes from svc_consoleplayer after connecting
# For testing, you can get it from the game client's console
server_digest = "abc123..."  # 32-char MD5 hex string from server

if rcon.authenticate(server_digest):
    print("RCON authenticated!")

    # Execute commands
    print(rcon.send_command("playerlist"))
    print(rcon.send_command("sv_fraglimit 30"))
    print(rcon.send_command("kick 3 AFK"))
    print(rcon.send_command("map MAP02"))

rcon.close()
```

### REST API Wrapper Example

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

class RCONCommand(BaseModel):
    server_id: str
    command: str

class RCONResponse(BaseModel):
    success: bool
    output: str

# Server registry with RCON connections
servers = {}

@app.post("/api/rcon/execute", response_model=RCONResponse)
async def execute_rcon(cmd: RCONCommand):
    """Execute RCON command on specified server."""
    if cmd.server_id not in servers:
        raise HTTPException(404, "Server not found")

    rcon = servers[cmd.server_id]
    try:
        output = rcon.send_command(cmd.command)
        return RCONResponse(success=True, output=output)
    except Exception as e:
        return RCONResponse(success=False, output=str(e))

@app.post("/api/servers/{server_id}/kick/{player_id}")
async def kick_player(server_id: str, player_id: int, reason: str = ""):
    """Kick player from server."""
    cmd = f"kick {player_id} {reason}".strip()
    return await execute_rcon(RCONCommand(server_id=server_id, command=cmd))

@app.post("/api/servers/{server_id}/map/{map_name}")
async def change_map(server_id: str, map_name: str):
    """Change server map."""
    return await execute_rcon(
        RCONCommand(server_id=server_id, command=f"map {map_name}")
    )

@app.get("/api/servers/{server_id}/players")
async def get_players(server_id: str):
    """Get player list from server."""
    return await execute_rcon(
        RCONCommand(server_id=server_id, command="playerlist")
    )
```

---

## 7. Common Use Cases

### Automated Server Management

```python
# Rotate map every 30 minutes
rcon.send_command("sv_timelimit 30")

# End-of-match actions
rcon.send_command("showscores")
rcon.send_command("nextmap")
```

### Player Moderation

```python
# Get player list first
players = rcon.send_command("playerlist")
# Parse output to find player ID

# Kick specific player
rcon.send_command("kick 5 Violation of server rules")

# Permanent ban
rcon.send_command("ban 5 permanent Cheating")
```

### Dynamic Settings

```python
# Switch to competitive settings
rcon.send_command("sv_fraglimit 50")
rcon.send_command("sv_timelimit 20")
rcon.send_command("sv_friendlyfire 0")
rcon.send_command("sv_allowjump 0")

# Switch to casual settings
rcon.send_command("sv_fraglimit 0")
rcon.send_command("sv_timelimit 0")
rcon.send_command("sv_friendlyfire 1")
rcon.send_command("sv_allowjump 1")
```

### Server Announcements

```python
# Broadcast message
rcon.send_command("say Server will restart in 5 minutes!")

# Set MOTD
rcon.send_command('sv_motd "Welcome to NovaDoom! Rules at novadoom.com/rules"')
```

---

## 8. Error Handling

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| No response | Wrong port or server down | Verify server is running on correct port |
| Auth failed | Wrong password or digest | Ensure password matches `rcon_password` CVAR |
| Command ignored | Not authenticated | Call authenticate() before sending commands |
| Partial response | UDP packet loss | Implement retry logic with timeout |

### Recommended Practices

1. **Connection pooling** - Maintain persistent RCON connections per server
2. **Retry logic** - Retry failed commands up to 3 times
3. **Timeout handling** - Use 5-second timeout for responses
4. **Rate limiting** - Limit commands to ~10/second per server
5. **Logging** - Log all RCON commands for audit trail

---

## 9. Security Considerations

1. **Strong passwords** - Use randomly generated passwords (16+ chars)
2. **Unique passwords** - Different password per server
3. **Secure storage** - Store passwords encrypted in platform database
4. **Network security** - RCON should only be accessible from platform IPs
5. **Audit logging** - Log all RCON commands with timestamps
6. **Rate limiting** - Prevent command spam/abuse

---

## 10. Testing

### Verify RCON is Working

```bash
# From game client console:
rcon_password yourpassword
rcon playerlist
rcon say "Test message"
```

### Expected Output

```
playerlist output:
  ID  Name            Team  Ping  Status
  0   Player1         Blue  45    Playing
  1   Player2         Red   62    Playing
  2   Spectator1      Spec  30    Spectating
```

---

## Appendix A: Complete CVAR Reference

See `server/src/sv_cvarlist.cpp` for the complete list of server CVARs.

## Appendix B: Network Protocol Reference

| File | Description |
|------|-------------|
| `common/i_net.h` | Message type enums (`svc_t`, `clc_t`) and buffer utilities |
| `common/i_net.cpp` | Network message info tables |
| `odaproto/server.proto` | Protobuf definitions for server-to-client messages |
| `common/svc_message.cpp` | Server message construction functions |
| `common/svc_message.h` | Server message function declarations |
| `server/src/sv_main.cpp` | Server connection and RCON handling |
| `client/src/cl_main.cpp` | Client RCON password command implementation |
| `client/src/cl_parse.cpp` | Client message parsing (including `svc_consoleplayer`) |

## Appendix C: Key Constants

```cpp
// From common/i_net.h
#define MAX_UDP_PACKET 8192       // Max buffer size
#define MAX_UDP_SIZE 1200         // Safe transmission size
#define SERVERPORT 10666          // Default server port
#define PROTO_CHALLENGE -5560020  // Protobuf connection challenge
#define VERSION 65                // Protocol version

// Message type values (0-indexed enums)
// clc_t (client-to-server):
//   clc_rcon = 9 (0x09)
//   clc_rcon_password = 10 (0x0A)
//
// svc_t (server-to-client):
//   svc_consoleplayer = 11 (0x0B)
//   svc_print = 21 (0x15)
```

## Appendix D: Troubleshooting

### "Why does authentication work from game client but not platform?"

- Ensure you're sending packets from the same IP that connected (digest is IP-specific)
- Verify the digest hasn't changed (reconnection generates new digest)
- Check packet format matches exactly (null-terminated strings, correct byte order)

--- 

## Appendix E: RCON-Only Connection (Slot-less, Implemented)

### Feature Status: IMPLEMENTED

The NovaDoom engine now supports **RCON-only connections** that:
- Do NOT consume a player slot
- Are NOT visible in the player list
- Provide a lightweight authenticated RCON session
- Are ideal for platform/web-based server management

### Protocol: RCON_CHALLENGE

A new challenge constant has been added:

```cpp
#define RCON_CHALLENGE -5560021   // RCON-only connection (no player slot)
```

### How It Works

```
┌─────────────────┐                      ┌─────────────────┐
│  NovaDoom API   │                      │   Game Server   │
└────────┬────────┘                      └────────┬────────┘
         │                                        │
         │  1. Get server token (same as before)  │
         │     LAUNCHER_CHALLENGE (777123)        │
         │ ──────────────────────────────────────>│
         │                                        │
         │  2. Receive token                      │
         │ <──────────────────────────────────────│
         │                                        │
         │  3. Send RCON challenge                │
         │     RCON_CHALLENGE (-5560021) + token  │
         │ ──────────────────────────────────────>│
         │                                        │
         │  4. Receive digest (no player slot!)   │
         │     RCON_CHALLENGE + digest string     │
         │ <──────────────────────────────────────│
         │                                        │
         │  5. Authenticate RCON                  │
         │     clc_rcon_password (0x0A)           │
         │ ──────────────────────────────────────>│
         │                                        │
         │  6. Receive auth result                │
         │     "RCON authenticated" or error      │
         │ <──────────────────────────────────────│
         │                                        │
         │  7. Send RCON commands                 │
         │     clc_rcon (0x09) + command          │
         │ ──────────────────────────────────────>│
         │                                        │
```

### Packet Formats

#### RCON Challenge Request
```
Offset  Size    Field               Value
──────────────────────────────────────────────────────────────
0       4       challenge           RCON_CHALLENGE (-5560021, signed int32 LE)
4       4       server_token        Token from launcher query (int32 LE)
```

#### RCON Challenge Response
```
Offset  Size    Field               Description
──────────────────────────────────────────────────────────────
0       4       challenge           RCON_CHALLENGE (-5560021)
4       ...     digest              32-char MD5 hex string (null-terminated)
```

#### RCON Auth/Command Packets (same as regular RCON)
```
Offset  Size    Field               Description
──────────────────────────────────────────────────────────────
0       4       sequence            Packet sequence (use 0)
4       1       flags               Packet flags (use 0)
5       1       marker              clc_rcon_password (0x0A) or clc_rcon (0x09)
6       ...     payload             Auth: login_byte + MD5_string
                                    Command: command_string (null-terminated)
```

### Python Implementation (Complete)

```python
import socket
import hashlib
from struct import pack, unpack

class NovaDoomRCON:
    """
    RCON client using the new slot-less RCON_CHALLENGE protocol.
    Does NOT consume a player slot on the server.
    """

    LAUNCHER_CHALLENGE = 777123
    RCON_CHALLENGE = -5560021  # Signed int32
    CLC_RCON = 0x09
    CLC_RCON_PASSWORD = 0x0A

    def __init__(self, host: str, port: int, password: str):
        self.host = host
        self.port = port
        self.password = password
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.socket.settimeout(5.0)
        self.digest = None
        self.authenticated = False

    def connect(self) -> bool:
        """
        Establish RCON-only session (no player slot consumed).
        Returns True if digest was received successfully.
        """
        # Step 1: Get server token
        self.socket.sendto(pack('<I', self.LAUNCHER_CHALLENGE), (self.host, self.port))
        data, _ = self.socket.recvfrom(8192)
        _, token = unpack('<II', data[:8])

        # Step 2: Send RCON challenge (slot-less connection)
        packet = pack('<i', self.RCON_CHALLENGE)  # Signed int32
        packet += pack('<I', token)
        self.socket.sendto(packet, (self.host, self.port))

        # Step 3: Receive digest
        data, _ = self.socket.recvfrom(8192)
        challenge_response = unpack('<i', data[:4])[0]
        if challenge_response != self.RCON_CHALLENGE:
            return False

        # Extract null-terminated digest string
        self.digest = data[4:].split(b'\x00')[0].decode('utf-8')
        return len(self.digest) == 32

    def authenticate(self) -> bool:
        """Authenticate with RCON password."""
        if not self.digest:
            raise Exception("Must call connect() first")

        challenge = hashlib.md5((self.password + self.digest).encode()).hexdigest()

        # Build auth packet
        packet = pack('<I', 0)  # sequence
        packet += pack('<B', 0)  # flags
        packet += pack('<B', self.CLC_RCON_PASSWORD)
        packet += pack('<B', 1)  # login = true
        packet += challenge.encode() + b'\x00'

        self.socket.sendto(packet, (self.host, self.port))

        try:
            response, _ = self.socket.recvfrom(8192)
            if b"RCON authenticated" in response:
                self.authenticated = True
                return True
            elif b"Bad password" in response:
                return False
        except socket.timeout:
            pass

        return False

    def command(self, cmd: str) -> str:
        """Send RCON command and receive response."""
        if not self.authenticated:
            raise Exception("Must authenticate first")

        packet = pack('<I', 0)  # sequence
        packet += pack('<B', 0)  # flags
        packet += pack('<B', self.CLC_RCON)
        packet += cmd.encode() + b'\x00'

        self.socket.sendto(packet, (self.host, self.port))

        # Collect responses
        responses = []
        try:
            while True:
                data, _ = self.socket.recvfrom(8192)
                # Simple extraction - find printable text after header
                text = data[7:].decode('utf-8', errors='ignore').split('\x00')[0]
                if text:
                    responses.append(text)
        except socket.timeout:
            pass

        return '\n'.join(responses)

    def close(self):
        """Close the connection."""
        self.socket.close()


# Usage example
if __name__ == "__main__":
    rcon = NovaDoomRCON("localhost", 10666, "secretpassword")

    if rcon.connect():
        print(f"Connected! Digest: {rcon.digest}")

        if rcon.authenticate():
            print("Authenticated!")

            # Execute commands
            print(rcon.command("playerlist"))
            print(rcon.command("sv_hostname"))

    rcon.close()
```

### Session Management

RCON sessions are automatically cleaned up:
- Sessions timeout after **5 minutes** of inactivity
- Each command resets the activity timer
- Multiple RCON sessions can exist simultaneously
- Sessions are tracked separately from players

### Implementation Files

| File | Changes |
|------|---------|
| `common/i_net.h` | Added `RCON_CHALLENGE` constant and `rcon_session_t` struct |
| `server/src/sv_main.cpp` | Added RCON session handling functions |

### Key Functions Added

```cpp
// Find RCON session by network address
rcon_session_t* SV_FindRconSession(const netadr_t& addr);

// Remove expired RCON sessions (called every tick)
void SV_CleanupRconSessions();

// Handle RCON_CHALLENGE connection request
void SV_HandleRconChallenge();

// Handle RCON password auth for sessions
void SV_RconSessionPassword(rcon_session_t& session);

// Handle RCON command from session
void SV_RconSessionCommand(rcon_session_t& session);
```

### Benefits for Platform Team

1. **No player slot consumed** - RCON sessions don't count against `sv_maxclients`
2. **Not visible in player list** - Clean separation from actual players
3. **Lightweight protocol** - No game state sync, just auth + commands
4. **Simple implementation** - ~100 lines of Python vs full game client
5. **Multiple sessions** - Platform can maintain connections to many servers
