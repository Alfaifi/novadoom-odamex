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
| `odalaunch` | `novalaunch` | Pending |
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
| `README.md` | Rewritten for NovaDoom | Done |
| `common/d_main.cpp` | WAD references updated | Done |
| `wad/CMakeLists.txt` | novadoom.wad references | Done |
| `.github/workflows/novadoom-release.yml` | WAD references updated | Done |

### Windows Resources (.rc.in) - PENDING

**Client:** `client/sdl/client.rc.in`
- Line 9: `#define ODAMEX_DESC "Odamex Client"` → `"NovaDoom Client"`
- Line 10: `#define ODAMEX_EXE "odamex.exe"` → `"novadoom.exe"`
- Line 11: `#define ODAMEX_INTERNAL "odamex"` → `"novadoom"`
- Line 12: `#define ODAMEX_NAME "Odamex Client"` → `"NovaDoom Client"`
- Line 14: Icon reference `odamex.ico` → `novadoom.ico`
- Line 41: Update copyright string

**Server:** `server/win32/server.rc.in`
- Line 7: `#define ODASRV_DESC "Odamex Server"` → `"NovaDoom Server"`
- Line 8: `#define ODASRV_EXE "odasrv.exe"` → `"novasrv.exe"`
- Line 9: `#define ODASRV_INTERNAL "odasrv"` → `"novasrv"`
- Line 10: `#define ODASRV_NAME "Odamex Server"` → `"NovaDoom Server"`
- Line 12: Icon reference → update
- Line 36: Update copyright string

**Launcher:** `odalaunch/res/odalaunch.rc.in`
- Line 7: `#define ODALAUNCH_DESC "Odamex Launcher"` → `"NovaDoom Launcher"`
- Line 8: `#define ODALAUNCH_EXE "odalaunch.exe"` → `"novalaunch.exe"`
- Line 9: `#define ODALAUNCH_INTERNAL "odalaunch"` → `"novalaunch"`
- Line 10: `#define ODALAUNCH_NAME "Odamex Launcher"` → `"NovaDoom Launcher"`
- Line 12: Icon reference → update
- Line 36: Update copyright string

### macOS Bundle Config - PENDING

**Launcher Plist:** `odalaunch/res/Info.plist`
- Line 8: `org.odalaunch.app` → `org.novadoom.launcher`
- Line 12: `OdaLaunch` → `NovaLaunch`
- Line 14: `odalaunch.icns` → `novalaunch.icns`
- Line 16: `Odalaunch` → `NovaDoom Launcher`
- Line 26, 30: Update copyright strings

**Launcher CMake:** `odalaunch/CMakeLists.txt`
- Line 69: `MACOSX_BUNDLE_BUNDLE_NAME OdaLaunch` → `NovaLaunch`
- Line 70: Update `MACOSX_BUNDLE_INFO_STRING` copyright
- Line 75: `net.odamex.odalaunch` → `net.novadoom.launcher`

**AG-Launcher CMake:** `ag-odalaunch/CMakeLists.txt`
- Line 39: `MACOSX_BUNDLE_BUNDLE_NAME AG-OdaLaunch` → `AG-NovaLaunch`
- Line 40: Update `MACOSX_BUNDLE_INFO_STRING` copyright
- Line 45: `net.odamex.ag-odalaunch` → `net.novadoom.ag-launcher`

### Windows Installer - PENDING

**File:** `installer/windows/odamex.iss`
- Line 9: `#define OdamexName "Odamex"` → `"NovaDoom"`
- Line 10: `#define OdamexPublisher "Odamex Development Team"` → `"NovaDoom Team"`
- Line 11: `#define OdamexURL "https://odamex.net/"` → Your NovaDoom URL
- Line 29: `OutputBaseFilename` → rename output to `novadoom-win-...`
- Line 38: `UninstallDisplayIcon` → `novadoom.exe`
- Rename file to `novadoom.iss`

### Linux Packaging - PENDING

**Desktop Files:** (rename files too)
- `packaging/linux/net.odamex.Odamex.Client.desktop` → `net.novadoom.NovaDoom.Client.desktop`
- `packaging/linux/net.odamex.Odamex.Server.desktop` → `net.novadoom.NovaDoom.Server.desktop`
- `packaging/linux/net.odamex.Odamex.Launcher.desktop` → `net.novadoom.NovaDoom.Launcher.desktop`
- `installer/arch/odamex.desktop` → `novadoom.desktop`

**AppStream Metadata:** `packaging/linux/net.odamex.Odamex.metainfo.xml` → `net.novadoom.NovaDoom.metainfo.xml`

**Flatpak Manifest:** `packaging/flatpak/net.odamex.Odamex.yml` → `net.novadoom.NovaDoom.yml`

---

## Priority 2: Icons & Assets - IN PROGRESS

### Icons to Replace

Use icons from `icons/` folder to create:

| Target File | Source | Status |
|-------------|--------|--------|
| `client/sdl/odamex.ico` → `novadoom.ico` | `icons/ND_favicon.ico` | Pending |
| `media/odamex.icns` → `novadoom.icns` | Create .icns from ND_*.png | Pending |
| `media/icon_odamex_512.png` | `icons/ND_512.png` | Pending |
| `media/icon_odamex_256.png` | `icons/ND_256.png` | Pending |
| `media/icon_odamex_128.png` | `icons/ND_128.png` | Pending |
| `media/icon_odamex_96.png` | Resize from ND_128.png | Pending |
| `media/odasrv.icns` → `novasrv.icns` | Create .icns | Pending |
| `media/icon_odasrv_*.png` | Copy from ND_*.png | Pending |
| `media/odalaunch.icns` → `novalaunch.icns` | Create .icns | Pending |
| `media/icon_odalaunch_*.png` | Copy from ND_*.png | Pending |
| `odalaunch/res/odalaunch.icns` | Copy from media/ | Pending |
| `ag-odalaunch/res/odalaunch.icns` | Copy from media/ | Pending |
| `client/switch/assets/odamex.jpg` → `novadoom.jpg` | Create from ND_512.png | Pending |

### Embedded Icon in Code

- `client/gui/icon_odamex_128.png.cpp` - Regenerate with new icon
- `client/fluid/icon_odamex_128.png` - Replace with new icon

---

## Priority 3: URLs to Update - PENDING

| Current | New |
|---------|-----|
| `https://odamex.net` | Your NovaDoom website |
| `https://github.com/odamex/odamex` | `https://github.com/Alfaifi/novadoom-odamex` |
| `https://odamex.net/wiki/` | Your wiki URL |
| `https://odamex.net/boards/` | Your forums URL |
| `https://odamex.net/bugs/` | Your bug tracker URL |

**Master Servers** (in `server/src/sv_master.cpp`):
- `master1.odamex.net` - Keep as fallback or add your own

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

## Files to Rename - PARTIAL

| Current Path | New Path | Status |
|--------------|----------|--------|
| `wad/odamex.wad` | `wad/novadoom.wad` | Done |
| `client/sdl/odamex.ico` | `client/sdl/novadoom.ico` | Pending |
| `media/odamex.icns` | `media/novadoom.icns` | Pending |
| `media/odasrv.icns` | `media/novasrv.icns` | Pending |
| `media/odalaunch.icns` | `media/novalaunch.icns` | Pending |
| `media/icon_odamex_*.png` | `media/icon_novadoom_*.png` | Pending |
| `media/icon_odasrv_*.png` | `media/icon_novasrv_*.png` | Pending |
| `media/icon_odalaunch_*.png` | `media/icon_novalaunch_*.png` | Pending |
| `installer/windows/odamex.iss` | `installer/windows/novadoom.iss` | Pending |
| `installer/arch/odamex.desktop` | `installer/arch/novadoom.desktop` | Pending |
| `packaging/linux/net.odamex.Odamex.*.desktop` | `packaging/linux/net.novadoom.NovaDoom.*.desktop` | Pending |
| `packaging/linux/net.odamex.Odamex.metainfo.xml` | `packaging/linux/net.novadoom.NovaDoom.metainfo.xml` | Pending |
| `packaging/flatpak/net.odamex.Odamex.yml` | `packaging/flatpak/net.novadoom.NovaDoom.yml` | Pending |

---

## Workflow - COMPLETED

The GitHub Actions workflow (`.github/workflows/novadoom-release.yml`):
- Names the release "NovaDoom" - Done
- Renames executables to `novadoom.exe` / `novasrv.exe` / `novasrv` - Done
- Creates `NovaDoom.app` bundle - Done
- Uses `wad/novadoom.wad` - Done
