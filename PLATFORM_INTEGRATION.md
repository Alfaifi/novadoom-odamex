# NovaDoom Platform Integration Guide

This guide explains how to integrate novasrv (server) and novadoom (client) into the NovaDoom game server management platform.

---

## 1. WAD File Access

**Local file paths are required.** The server cannot stream WADs directly from R2 or remote storage.

### How it works

```bash
# Specify IWAD (required)
./novasrv -iwad /path/to/doom2.wad

# Add PWADs/mods
./novasrv -iwad /path/to/doom2.wad -file /path/to/mod1.wad /path/to/mod2.wad

# Or set search directories via CVAR
./novasrv +set waddirs "/wads:/iwads"
```

### Platform Integration

- Download WADs from R2 to a local directory on the server instance (e.g., `/data/wads/`)
- Pass paths via command-line arguments
- The `waddirs` CVAR can specify multiple search directories (colon-separated on Linux)

---

## 2. Configuration

**Both command-line args AND config file are supported.**

### Command-line approach (recommended for platform)

```bash
./novasrv -iwad /wads/doom2.wad -file /wads/mymod.wad \
  +set sv_hostname "My Server" \
  +set sv_gametype 0 \
  +set sv_skill 3 \
  +set sv_maxplayers 8 \
  +set sv_downloadsites "https://wads.novadoom.platform/files/"
```

### Config file approach

```bash
# Use custom config location
./novasrv -config /data/configs/server1.cfg
```

Config file format (`server1.cfg`):
```
// Server configuration
set sv_hostname "My Server"
set sv_gametype 0
set sv_skill 3
set sv_maxplayers 8
set sv_downloadsites "https://wads.novadoom.platform/files/"
```

### Recommendation

Use command-line `+set` arguments for dynamic configuration. This allows the platform to generate server launch commands without managing config files.

---

## 3. WAD Distribution to Clients

**NovaDoom has built-in HTTP WAD downloading.** Clients automatically download missing WADs when joining a server.

### How It Works

```
┌─────────────┐     1. Connect      ┌─────────────┐
│   Client    │ ─────────────────▶  │   Server    │
└─────────────┘                     └─────────────┘
       │                                   │
       │  2. Server sends WAD list         │
       │     + download URLs               │
       │  ◀────────────────────────────────│
       │                                   │
       │  3. Client checks local WADs      │
       │     Missing: mod.wad              │
       │                                   │
       ▼
┌─────────────────────────────────────────────┐
│  4. HTTP GET https://wads.platform/mod.wad  │
│     (from sv_downloadsites URL)             │
└─────────────────────────────────────────────┘
       │
       │  5. Download complete, MD5 verified
       │
       ▼
┌─────────────┐     6. Reconnect    ┌─────────────┐
│   Client    │ ─────────────────▶  │   Server    │
│  (has WAD)  │                     └─────────────┘
└─────────────┘
```

### Server Configuration Required

```bash
# Point to your R2 bucket or CDN endpoint
+set sv_downloadsites "https://wads.novadoom.platform/files/"
```

Multiple URLs supported (space-separated, tried in order):
```bash
+set sv_downloadsites "https://primary-cdn.com/wads/ https://backup-cdn.com/wads/"
```

### R2/CDN Requirements

| Requirement | Details |
|-------------|---------|
| **File format** | Uncompressed `.wad` files (no ZIP) |
| **URL structure** | `{base_url}/{filename.wad}` |
| **Content-Type** | `application/octet-stream` (or any) |
| **CORS** | Not required (native HTTP, not browser) |
| **HTTPS** | Supported and recommended |

**Example:** If server needs `brutaldoom.wad` and `sv_downloadsites` is `https://r2.novadoom.platform/wads/`, client will request:
```
https://r2.novadoom.platform/wads/brutaldoom.wad
```

### Client-Side Behavior

- Downloads happen automatically when joining a server
- Progress shown in-game
- Files saved to user's download directory
- MD5 hash validation ensures integrity
- **Commercial IWADs (DOOM.WAD, DOOM2.WAD, etc.) are blocked from download** - users must own these

---

## Complete Platform Integration Example

### Server Launch Command

```bash
./novasrv \
  -iwad /data/wads/iwads/doom2.wad \
  -file /data/wads/pwads/mydeathmatch.wad \
  +set sv_hostname "NovaDoom Platform Server #1" \
  +set sv_gametype 1 \
  +set sv_maxplayers 16 \
  +set sv_fraglimit 30 \
  +set sv_timelimit 15 \
  +set sv_downloadsites "https://r2.novadoom.platform/wads/" \
  +set sv_motd "Welcome to NovaDoom Platform!"
```

### Platform Workflow

1. User creates server on platform, selects WADs from library
2. Platform downloads required WADs from R2 to server instance
3. Platform generates launch command with local paths + R2 download URL
4. Server starts with `sv_downloadsites` pointing to R2
5. Clients connect, automatically download missing WADs from R2
6. Players join with all required files

---

## Key CVARs Reference

| CVAR | Purpose | Example |
|------|---------|---------|
| `sv_downloadsites` | URL(s) for client WAD downloads | `"https://r2.novadoom.platform/wads/"` |
| `sv_hostname` | Server name shown in browser | `"My Server"` |
| `sv_maxplayers` | Max concurrent players | `16` |
| `sv_gametype` | 0=Coop, 1=DM, 2=TDM, 3=CTF, 4=Horde | `1` |
| `waddirs` | Server WAD search paths | `"/data/wads"` |

---

## Command-Line Reference

### Server Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `-iwad <path>` | Specify IWAD file (required) | `-iwad /wads/doom2.wad` |
| `-file <paths>` | Load PWAD files | `-file mod1.wad mod2.wad` |
| `-config <path>` | Use custom config file | `-config /configs/server.cfg` |
| `+set <cvar> <value>` | Set a CVAR | `+set sv_hostname "My Server"` |
| `+exec <file>` | Execute a config file | `+exec settings.cfg` |

### Game Types

| Value | Mode |
|-------|------|
| `0` | Cooperative |
| `1` | Deathmatch |
| `2` | Team Deathmatch |
| `3` | Capture The Flag |
| `4` | Horde |

### Skill Levels

| Value | Difficulty |
|-------|------------|
| `1` | I'm Too Young to Die |
| `2` | Hey, Not Too Rough |
| `3` | Hurt Me Plenty |
| `4` | Ultra-Violence |
| `5` | Nightmare |

---

## Summary

| Question | Answer |
|----------|--------|
| WAD access | **Local paths required** - download from R2 to server first |
| Configuration | **Both supported** - recommend `+set` command-line args |
| Client downloads | **Built-in HTTP download** - set `sv_downloadsites` to R2 URL |
| User experience | **Seamless** - clients auto-download missing WADs on join |
