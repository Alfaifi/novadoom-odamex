# NovaDoom Rebranding Guide

This document outlines all changes needed to rebrand Odamex to NovaDoom.

## New Icons Available

New NovaDoom icons are located in `icons/`:
- `ND_512.png`, `ND_256.png`, `ND_192.png`, `ND_180.png`, `ND_128.png`, `ND_64.png`, `ND_48.png`, `ND_32.png`, `ND_16.png`
- `ND_favicon.ico`
- `ND_maskable_1024.png`

---

## Priority 1: User-Visible / Critical - COMPLETED

### Executable Names - COMPLETED

| Current | New | Status |
|---------|-----|--------|
| `odamex` | `novadoom` | Done |
| `odasrv` | `novasrv` | Done |
| `odalaunch` | `novalaunch` | Done |
| `odamex.wad` | `novadoom.wad` | Done |

### Core Branding Files - COMPLETED

| File | What to Change | Status |
|------|----------------|--------|
| `CMakeLists.txt:17` | `project(NovaDoom VERSION 0.0.1)` | Done |
| `common/version.h:28,30` | `GAMEEXE "novadoom"` / `"novasrv"` | Done |
| `common/version.h:80` | `COPYRIGHTSTR` updated | Done |
| `common/version.h:94` | `SAVESIG "NOVADOOMSAV00001"` | Done |
| `common/version.cpp:327` | `"NovaDoom v{}"` | Done |
| `client/src/d_main.cpp:1083` | `"NovaDoom Client Initialized"` | Done |
| `client/src/d_main.cpp:1085` | `"use the NovaDoom Launcher"` | Done |
| `client/gui/gui_boot.cpp:617` | Window title `"NovaDoom "` | Done |
| `client/sdl/i_system.cpp:978` | Error dialog title `"NovaDoom"` | Done |
| `client/sdl/i_main.cpp` | Version output `"NovaDoom"` | Done |
| `server/src/i_main.cpp` | Version output `"NovaDoom"` | Done |
| `README.md` | Rewritten for NovaDoom | Done |
| `common/d_main.cpp` | WAD references updated | Done |
| `wad/CMakeLists.txt` | novadoom.wad references | Done |
| `.github/workflows/novadoom-release.yml` | WAD references updated | Done |

### Windows Resources (.rc.in) - COMPLETED

| File | Status |
|------|--------|
| `client/sdl/client.rc.in` | Done - Updated to NovaDoom Client |
| `server/win32/server.rc.in` | Done - Updated to NovaDoom Server |
| `odalaunch/res/odalaunch.rc.in` | Done - Updated to NovaDoom Launcher |

### macOS Bundle Config - COMPLETED

| File | Status |
|------|--------|
| `client/CMakeLists.txt` | Done - novadoom.icns, net.novadoom.client |
| `odalaunch/res/Info.plist` | Done - net.novadoom.launcher |
| `odalaunch/CMakeLists.txt` | Done - NovaLaunch, net.novadoom.launcher |
| `ag-odalaunch/CMakeLists.txt` | Done - AG-NovaLaunch, net.novadoom.ag-launcher |

### Windows Installer - COMPLETED

| File | Status |
|------|--------|
| `installer/windows/novadoom.iss` | Done - Created (replaced odamex.iss) |

### Linux Packaging - COMPLETED

| File | Status |
|------|--------|
| `packaging/linux/net.novadoom.NovaDoom.Client.desktop` | Done |
| `packaging/linux/net.novadoom.NovaDoom.Server.desktop` | Done |
| `packaging/linux/net.novadoom.NovaDoom.Launcher.desktop` | Done |
| `packaging/linux/net.novadoom.NovaDoom-mime.xml` | Done |
| `packaging/linux/net.novadoom.NovaDoom.metainfo.xml` | Done |
| `packaging/flatpak/net.novadoom.NovaDoom.yml` | Done |
| `installer/arch/novadoom.desktop` | Done |
| `installer/arch/novalaunch.desktop` | Done |
| `installer/arch/novasrv.desktop` | Done |

---

## Priority 2: Icons & Assets - COMPLETED

### Icons Replaced

| Target File | Status |
|-------------|--------|
| `client/sdl/novadoom.ico` | Done |
| `media/novadoom.icns` | Done |
| `media/icon_novadoom_512.png` | Done |
| `media/icon_novadoom_256.png` | Done |
| `media/icon_novadoom_128.png` | Done |
| `media/icon_novadoom_96.png` | Done |
| `media/novasrv.icns` | Done |
| `media/icon_novasrv_*.png` | Done |
| `media/novalaunch.icns` | Done |
| `media/icon_novalaunch_*.png` | Done |
| `odalaunch/res/novalaunch.icns` | Done |
| `ag-odalaunch/res/novalaunch.icns` | Done |

### Embedded Icon in Code - COMPLETED

| File | Status |
|------|--------|
| `client/gui/icon_novadoom_128.png.cpp` | Done |
| `client/fluid/icon_novadoom_128.png` | Done |
| `client/gui/gui_resource.h` | Done |
| `client/gui/gui_common.h` | Done |
| `client/gui/gui_common.cpp` | Done |
| `client/gui/gui_boot.cpp` | Done |
| `client/fluid/boot.fl` | Done |

---

## Priority 3: URLs to Update - COMPLETED

| Current | New | Status |
|---------|-----|--------|
| `https://odamex.net` | `https://novadoom.com` | Done |
| `https://github.com/odamex/odamex` | `https://github.com/Alfaifi/novadoom-odamex` | Done |
| `https://odamex.net/wiki/` | `https://github.com/Alfaifi/novadoom-odamex/wiki` | Done |
| `https://odamex.net/boards/` | `https://novadoom.com/boards` | Done |
| `https://odamex.net/bugs/` | `https://github.com/Alfaifi/novadoom-odamex/issues` | Done |

**Files Updated:**
- `server/src/sv_main.cpp` - Version mismatch messages
- `client/src/cl_demo.cpp` - Demo version messages
- `common/m_stacktrace.cpp` - Error reporting URL
- `odalaunch/src/dlg_main.cpp` - All menu URLs
- `odalaunch/res/xrc_resource.xrc` - About dialog URL
- `odalaunch/res/gui_project.fbp` - Form builder URL
- `ag-odalaunch/src/agol_about.cpp` - About dialog URL
- `ag-odalaunch/src/agol_main.cpp` - Bug report URL
- `CMakeLists.txt` - Debian package homepage
- `docker/Makefile` - Repository URL
- `docker/examples/configs/config.cfg` - Wiki and website URLs
- `installer/arch/PKGBUILD` - Package URL
- `config-samples/*.cfg` - All config sample wiki links
- `.github/FUNDING.yml` - Sponsorship URL
- `MAINTAINERS` - Project URLs
- `CLAUDE.md` - Clone URL
- Removed old `README` file (using `README.md` only)

**Master Servers** (in `server/src/sv_master.cpp` and `odalaunch/src/oda_defs.h`):
- Kept `master1.odamex.net` as fallback for compatibility

---

## Priority 4: CMake Configuration - PARTIAL

### Main CMakeLists.txt

| Line | Change | Status |
|------|--------|--------|
| 17 | `project(NovaDoom VERSION 0.0.1)` | Done |
| 26 | `ODAMEX_NO_GITVER` → `NOVADOOM_NO_GITVER` | Pending |
| 28 | `-DODAMEX_NO_GITVER` → `-DNOVADOOM_NO_GITVER` | Pending |
| 53 | `ODAMEX_INSTALL_BINDIR` → `NOVADOOM_INSTALL_BINDIR` | Pending |
| 54 | `ODAMEX_INSTALL_DATADIR` → `NOVADOOM_INSTALL_DATADIR` | Pending |
| 71-77 | Update all `ODAMEX_*` definitions | Pending |
| 81 | `PROJECT_RC_VERSION "0,0,1,0"` | Done |
| 82 | `PROJECT_COMPANY "NovaDoom"` | Done |
| 216 | `CPACK_PACKAGE_INSTALL_DIRECTORY Odamex` → `NovaDoom` | Pending |
| 221 | `CPACK_COMPONENT_CLIENT_DISPLAY_NAME "Odamex"` → `"NovaDoom"` | Pending |
| 223 | `"Odamex Dedicated Server"` → `"NovaDoom Dedicated Server"` | Pending |
| 225 | `"Odalaunch Odamex Server Browser..."` → `"NovaDoom Launcher..."` | Pending |
| 241, 244 | `odamex` directory → `novadoom` | Pending |
| 262 | `CPACK_PACKAGE_VENDOR` → `"NovaDoom Team"` | Pending |
| 267 | `CPACK_DEBIAN_PACKAGE_HOMEPAGE` → Your URL | Pending |

### Target CMakeLists - PENDING

**Client:** `client/CMakeLists.txt`
- Executable name `odamex` → `novadoom`

**Server:** `server/CMakeLists.txt`
- Line 40: `add_executable(odasrv ...)` → `add_executable(novasrv ...)`
- Line 97: Error message update

**Launcher:** `odalaunch/CMakeLists.txt`
- Line 55: `add_executable(odalaunch ...)` → `add_executable(novalaunch ...)`

**WAD:** `wad/CMakeLists.txt` - DONE

---

## Priority 5: Internal Code (Lower Priority) - PENDING

### Copyright Headers

~100+ source files contain:
```
Copyright (C) 2006-2025 by The Odamex Team
```

Can be updated with a script to:
```
Copyright (C) 2006-2025 by The Odamex Team
Portions Copyright (C) 2025 by The NovaDoom Team
```

### Config Directories

- `~/.odamex` → `~/.novadoom` (search for references in code)

### Protocol Handlers

- `odamex://` → `novadoom://`
- `application/odamex-demo` → `application/novadoom-demo`

### Function Names (Optional)

Internal functions like `getOdaMobjinfo()` can remain unchanged as they're not user-visible.

---

## Files Renamed - COMPLETED

| Old Path | New Path | Status |
|----------|----------|--------|
| `wad/odamex.wad` | `wad/novadoom.wad` | Done |
| `client/sdl/odamex.ico` | `client/sdl/novadoom.ico` | Done |
| `media/odamex.icns` | `media/novadoom.icns` | Done |
| `media/odasrv.icns` | `media/novasrv.icns` | Done |
| `media/odalaunch.icns` | `media/novalaunch.icns` | Done |
| `media/icon_odamex_*.png` | `media/icon_novadoom_*.png` | Done |
| `media/icon_odasrv_*.png` | `media/icon_novasrv_*.png` | Done |
| `media/icon_odalaunch_*.png` | `media/icon_novalaunch_*.png` | Done |
| `installer/windows/odamex.iss` | `installer/windows/novadoom.iss` | Done |
| `installer/arch/odamex.desktop` | `installer/arch/novadoom.desktop` | Done |
| `installer/arch/odalaunch.desktop` | `installer/arch/novalaunch.desktop` | Done |
| `installer/arch/odasrv.desktop` | `installer/arch/novasrv.desktop` | Done |
| `packaging/linux/net.odamex.Odamex.*.desktop` | `packaging/linux/net.novadoom.NovaDoom.*.desktop` | Done |
| `packaging/linux/net.odamex.Odamex.metainfo.xml` | `packaging/linux/net.novadoom.NovaDoom.metainfo.xml` | Done |
| `packaging/flatpak/net.odamex.Odamex.yml` | `packaging/flatpak/net.novadoom.NovaDoom.yml` | Done |

---

## Workflow - COMPLETED

The GitHub Actions workflow (`.github/workflows/novadoom-release.yml`):
- Names the release "NovaDoom" - Done
- Renames executables to `novadoom.exe` / `novasrv.exe` / `novasrv` - Done
- Creates `NovaDoom.app` bundle - Done
- Uses `wad/novadoom.wad` - Done
