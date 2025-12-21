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

### Message Types

```
clc_rcon_password (0x0D) - Authentication message
clc_rcon          (0x0C) - Command execution message
```

---

## 2. Authentication Flow

RCON uses a challenge-response authentication mechanism:

```
┌─────────────────┐                      ┌─────────────────┐
│  NovaDoom API   │                      │   Game Server   │
└────────┬────────┘                      └────────┬────────┘
         │                                        │
         │  1. Connect to server                  │
         │ ──────────────────────────────────────>│
         │                                        │
         │  2. Server sends unique digest         │
         │ <──────────────────────────────────────│
         │     (32-byte random string)            │
         │                                        │
         │  3. Send login request                 │
         │     clc_rcon_password                  │
         │     login=1                            │
         │     challenge=MD5(password + digest)   │
         │ ──────────────────────────────────────>│
         │                                        │
         │  4. Server validates                   │
         │     MD5(rcon_password + client_digest) │
         │     == challenge                       │
         │                                        │
         │  5. Auth success - allow_rcon=true     │
         │ <──────────────────────────────────────│
         │                                        │
         │  6. Send RCON command                  │
         │     clc_rcon + command_string          │
         │ ──────────────────────────────────────>│
         │                                        │
         │  7. Command output via SVC_Print       │
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

---

## 3. Packet Format

### Login Packet (clc_rcon_password)

```
Byte   Field         Description
─────────────────────────────────────────
0      marker        0x0D (clc_rcon_password)
1      login         0x01 (login) or 0x00 (logout)
2+     challenge     MD5 hash string (null-terminated)
```

### Command Packet (clc_rcon)

```
Byte   Field         Description
─────────────────────────────────────────
0      marker        0x0C (clc_rcon)
1+     command       Command string (null-terminated)
```

### Response Packet (SVC_Print)

```
Byte   Field         Description
─────────────────────────────────────────
0      marker        SVC_Print marker
1      level         Print level (1=HIGH, 3=CHAT, etc.)
2+     message       Response text (null-terminated)
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
    CLC_RCON = 0x0C
    CLC_RCON_PASSWORD = 0x0D

    def __init__(self, host: str, port: int, password: str):
        self.host = host
        self.port = port
        self.password = password
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.socket.settimeout(5.0)
        self.digest = None
        self.authenticated = False

    def connect(self):
        """Connect and receive server digest."""
        # Send initial connection packet
        # Server will respond with digest in player info
        pass  # Implementation depends on full protocol

    def _md5(self, data: str) -> str:
        """Calculate MD5 hash."""
        return hashlib.md5(data.encode()).hexdigest()

    def authenticate(self, server_digest: str) -> bool:
        """Authenticate with RCON password."""
        challenge = self._md5(self.password + server_digest)

        # Build login packet
        packet = bytes([self.CLC_RCON_PASSWORD, 0x01])  # login=true
        packet += challenge.encode() + b'\x00'

        self.socket.sendto(packet, (self.host, self.port))

        # Wait for response
        try:
            response, _ = self.socket.recvfrom(8192)
            self.authenticated = True
            return True
        except socket.timeout:
            return False

    def send_command(self, command: str) -> str:
        """Send RCON command and receive response."""
        if not self.authenticated:
            raise Exception("Not authenticated")

        # Build command packet
        packet = bytes([self.CLC_RCON])
        packet += command.encode() + b'\x00'

        self.socket.sendto(packet, (self.host, self.port))

        # Collect responses
        responses = []
        try:
            while True:
                data, _ = self.socket.recvfrom(8192)
                responses.append(self._parse_response(data))
        except socket.timeout:
            pass

        return '\n'.join(responses)

    def _parse_response(self, data: bytes) -> str:
        """Parse SVC_Print response."""
        # Skip marker and print level
        return data[2:].decode('utf-8', errors='ignore').rstrip('\x00')

    def logout(self):
        """Logout from RCON."""
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
rcon = NovaDoomRCON("game1.novadoom.com", 10666, "secretpassword")
rcon.connect()
rcon.authenticate(server_digest)

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

See `common/i_net.h` for protocol buffer definitions and message types.
