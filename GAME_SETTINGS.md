# NovaDoom Game Settings Reference

This document lists all available server-side settings for configuring game modes and gameplay options.

## Game Type

| Setting | Default | Description |
|---------|---------|-------------|
| `sv_gametype` | `0` | Game mode: 0=Cooperative, 1=Deathmatch, 2=Team DM, 3=CTF, 4=Horde |
| `g_gametypename` | `""` | Custom gametype display name |

## Movement & Controls

| Setting | Default | Description |
|---------|---------|-------------|
| `sv_allowjump` | `0` | Allow players to jump |
| `sv_freelook` | `0` | Allow looking up/down |
| `sv_gravity` | `800` | World gravity |
| `sv_aircontrol` | `0.00390625` | Air control during jumps |
| `sv_splashfactor` | `1.0` | Rocket explosion thrust effect |
| `sv_unblockplayers` | `0` | Players can walk through each other |
| `sv_allowmovebob` | `1` | Allow weapon/view bob adjustment |
| `sv_allowfov` | `0` | Allow FOV adjustment |
| `sv_allowwidescreen` | `1` | Allow widescreen modes |

## Items & Weapons

| Setting | Default | Description |
|---------|---------|-------------|
| `sv_itemsrespawn` | `0` | Items respawn after pickup |
| `sv_itemrespawntime` | `30` | Seconds before items respawn |
| `sv_respawnsuper` | `0` | Invisibility/invulnerability can respawn |
| `sv_weaponstay` | `1` | Weapons stay after pickup |
| `sv_weapondrop` | `0` | Drop weapon on death |
| `sv_infiniteammo` | `0` | Unlimited ammunition |
| `sv_doubleammo` | `0` | Double ammo from pickups |
| `sv_keepkeys` | `0` | Keep keys on death |
| `sv_sharekeys` | `0` | Share keys with all players |
| `sv_weapondamage` | `1.0` | Player weapon damage multiplier |
| `sv_allowpwo` | `0` | Allow preferred weapon order |

## Player Respawn

| Setting | Default | Description |
|---------|---------|-------------|
| `sv_forcerespawn` | `0` | Force player respawn |
| `sv_forcerespawntime` | `30` | Seconds before forced respawn |
| `sv_spawndelaytime` | `0.0` | Delay before respawn allowed |
| `g_lives` | `0` | Lives per player (0=unlimited) |

## Monsters

| Setting | Default | Description |
|---------|---------|-------------|
| `sv_nomonsters` | `0` | Disable all monsters |
| `sv_monstersrespawn` | `0` | Monsters respawn after death |
| `sv_fastmonsters` | `0` | Nightmare-speed monsters |
| `sv_monstershealth` | `1.0` | Monster health multiplier |
| `sv_monsterdamage` | `1.0` | Monster damage multiplier |
| `sv_skill` | `3` | Difficulty: 1=ITYTD, 2=HNTR, 3=HMP, 4=UV, 5=Nightmare |

## Team Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `sv_friendlyfire` | `1` | Team friendly fire enabled |
| `sv_friendlymonsterfire` | `1` | Friendly monster damage enabled |
| `sv_teamspawns` | `1` | Use team-specific spawn points |
| `sv_teamsinplay` | `2` | Number of teams (2-3) |
| `sv_maxplayersperteam` | `3` | Max players per team (0=unlimited) |
| `sv_unblockfriendly` | `0` | Friendlies pass through each other |

## Score & Time Limits

| Setting | Default | Description |
|---------|---------|-------------|
| `sv_fraglimit` | `0` | Frags to end game (0=unlimited) |
| `sv_scorelimit` | `5` | Team score limit for CTF/Team DM |
| `sv_timelimit` | `0` | Time limit in minutes (0=unlimited) |
| `sv_intermissionlimit` | `10` | Intermission duration in seconds |

## Rounds & Match Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `g_rounds` | `0` | Enable round-based gameplay |
| `g_roundlimit` | `0` | Total rounds allowed |
| `g_winlimit` | `0` | Rounds needed to win match |
| `g_sides` | `0` | Enable offensive/defensive sides |
| `g_winnerstays` | `0` | Winners stay, losers spectate |
| `g_preroundtime` | `5` | Pre-round time (no shooting) |
| `g_preroundreset` | `0` | Reset map after preround |
| `g_postroundtime` | `3` | Post-round freeze time |

## Warmup & Countdown

| Setting | Default | Description |
|---------|---------|-------------|
| `sv_warmup` | `0` | Enable warmup mode before match |
| `sv_warmup_autostart` | `1.0` | Player ratio needed to start |
| `sv_countdown` | `5` | Countdown seconds before start |

## CTF Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `ctf_manualreturn` | `0` | Must touch flag to return it |
| `ctf_flagathometoscore` | `1` | Your flag must be home to score |
| `ctf_flagtimeout` | `10` | Seconds before dropped flag returns |
| `g_ctf_notouchreturn` | `0` | Prevent touch-return (force timeout) |

## Horde Mode Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `g_horde_waves` | `5` | Number of waves per map |
| `g_horde_mintotalhp` | `4.0` | Minimum total health multiplier |
| `g_horde_maxtotalhp` | `10.0` | Maximum total health multiplier |
| `g_horde_goalhp` | `8.0` | Goal health multiplier |
| `g_horde_spawnempty_min` | `1` | Min spawn time when map empty |
| `g_horde_spawnempty_max` | `3` | Max spawn time when map empty |
| `g_horde_spawnfull_min` | `2` | Min spawn time when map full |
| `g_horde_spawnfull_max` | `6` | Max spawn time when map full |
| `g_horde_extralife` | `0.0` | Extra life powerup chance |
| `g_horde_resurrect` | `0.0` | Resurrect teammate powerup chance |

## Spawn Inventory

| Setting | Default | Description |
|---------|---------|-------------|
| `g_spawninv` | `"default"` | Starting inventory preset |
| `g_thingfilter` | `0` | Remove things from map (-1 to 3) |

## Server Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `sv_hostname` | `"Untitled NovaDoom Server"` | Server display name |
| `sv_motd` | `"Welcome to NovaDoom"` | Message of the day |
| `sv_maxclients` | `4` | Maximum connected clients |
| `sv_maxplayers` | `4` | Maximum active players |
| `sv_allowcheats` | `0` | Allow cheat commands |
| `sv_allowexit` | `1` | Allow exit switches |
| `sv_emptyreset` | `0` | Reload map when empty |
| `sv_emptyfreeze` | `0` | Freeze game when no players |
| `sv_maxcorpses` | `200` | Maximum corpses on map |

## Network & Anti-Lag

| Setting | Default | Description |
|---------|---------|-------------|
| `sv_maxrate` | `200` | Maximum client rate |
| `sv_maxunlagtime` | `1.0` | Max unlag reconciliation time |
| `sv_ticbuffer` | `1` | Buffer input for latency spikes |
| `sv_dmfarspawn` | `0` | DM spawn at farthest point (experimental) |

## Visual Options

| Setting | Default | Description |
|---------|---------|-------------|
| `sv_allowredscreen` | `1` | Allow pain screen intensity adjustment |
| `sv_allowshowspawns` | `1` | Allow spawn point fountains |
| `sv_allowtargetnames` | `0` | Show player names when targeted |
| `sv_showplayerpowerups` | `0` | Show player powerup indicators |

## Compatibility Flags

| Setting | Default | Description |
|---------|---------|-------------|
| `co_realactorheight` | `0` | Use real actor heights (not infinitely tall) |
| `co_boomphys` | `0` | Boom physics compatibility |
| `co_zdoomphys` | `0` | ZDoom gravity/physics |
| `co_pursuit` | `0` | MBF monster targeting |
| `co_helpfriends` | `0` | MBF friend helping behavior |
| `co_monsterbacking` | `0` | MBF monster retreat behavior |

## Voting System

| Setting | Default | Description |
|---------|---------|-------------|
| `sv_vote_majority` | `0.5` | Vote pass ratio (0.0-1.0) |
| `sv_vote_timelimit` | `30` | Vote duration in seconds |
| `sv_vote_timeout` | `60` | Cooldown between votes |

### Vote Types (set to `1` to enable)

| Setting | Description |
|---------|-------------|
| `sv_callvote_kick` | Vote to kick player |
| `sv_callvote_forcespec` | Vote to force spectator |
| `sv_callvote_forcestart` | Vote to force start |
| `sv_callvote_map` | Vote to change map |
| `sv_callvote_nextmap` | Vote for next map |
| `sv_callvote_randmap` | Vote for random map |
| `sv_callvote_restart` | Vote to restart map |
| `sv_callvote_fraglimit` | Vote to change frag limit |
| `sv_callvote_scorelimit` | Vote to change score limit |
| `sv_callvote_timelimit` | Vote to change time limit |
| `sv_callvote_coinflip` | Vote for coin flip |
| `sv_callvote_lives` | Vote to change lives |
| `sv_callvote_randcaps` | Vote for random captains |
| `sv_callvote_randpickup` | Vote for random pickup |

## Passwords

| Setting | Default | Description |
|---------|---------|-------------|
| `join_password` | `""` | Password to join server |
| `rcon_password` | `""` | Remote console password |

---

## Example Configurations

### Cooperative (Classic)
```
sv_gametype 0
sv_skill 3
sv_nomonsters 0
sv_itemsrespawn 0
sv_sharekeys 1
sv_allowjump 0
```

### Deathmatch
```
sv_gametype 1
sv_itemsrespawn 1
sv_weaponstay 0
sv_fraglimit 20
sv_timelimit 10
sv_allowjump 1
```

### Capture The Flag
```
sv_gametype 3
sv_scorelimit 5
sv_timelimit 20
ctf_flagathometoscore 1
ctf_flagtimeout 10
sv_friendlyfire 0
```

### Survival Cooperative
```
sv_gametype 0
g_lives 3
sv_forcerespawn 0
sv_sharekeys 1
sv_monstershealth 1.5
```

### Horde Mode
```
sv_gametype 4
g_horde_waves 10
g_horde_goalhp 8.0
g_lives 3
sv_sharekeys 1
```
