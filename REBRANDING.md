# NovaDoom Rebranding Guide

This document outlines all changes needed to rebrand Odamex to NovaDoom.

## New Icons Available

New NovaDoom icons are located in `icons/`:
- `ND_512.png`, `ND_256.png`, `ND_192.png`, `ND_180.png`, `ND_128.png`, `ND_64.png`, `ND_48.png`, `ND_32.png`, `ND_16.png`
- `ND_favicon.ico`
- `ND_maskable_1024.png`

---

## Priority 1: User-Visible / Critical

### Executable Names

| Current | New |
|---------|-----|
| `odamex` | `novadoom` |
| `odasrv` | `novasrv` |
| `odalaunch` | `novalaunch` |
| `odamex.wad` | `novadoom.wad` |

### Core Branding Files

| File | What to Change |
|------|----------------|
| `CMakeLists.txt:17` | `project(Odamex VERSION 12.0.0)` → `project(NovaDoom ...)` |
| `common/version.h:28,30` | `GAMEEXE "odamex"` / `"odasrv"` → `"novadoom"` / `"novasrv"` |
| `common/version.h:80` | `COPYRIGHTSTR` - Update copyright text |
| `common/version.h:94` | `SAVESIG "ODAMEXSAVE012000"` → `"NOVADOOMSAV12000"` (must be 16 chars) |
| `common/version.cpp:327` | `"Odamex v{}"` → `"NovaDoom v{}"` |
| `client/src/d_main.cpp:1083` | `"Odamex Client Initialized"` → `"NovaDoom Client Initialized"` |
| `client/src/d_main.cpp:1085` | `"use the Odamex Launcher"` → `"use the NovaDoom Launcher"` |
| `client/gui/gui_boot.cpp:617` | Window title `"Odamex "` → `"NovaDoom "` |
| `README.md` | Entire file needs rewrite |

### Windows Resources (.rc.in)

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

### macOS Bundle Config

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

### Windows Installer

**File:** `installer/windows/odamex.iss`
- Line 9: `#define OdamexName "Odamex"` → `"NovaDoom"`
- Line 10: `#define OdamexPublisher "Odamex Development Team"` → `"NovaDoom Team"`
- Line 11: `#define OdamexURL "https://odamex.net/"` → Your NovaDoom URL
- Line 29: `OutputBaseFilename` → rename output to `novadoom-win-...`
- Line 38: `UninstallDisplayIcon` → `novadoom.exe`
- Rename file to `novadoom.iss`

### Linux Packaging

**Desktop Files:** (rename files too)
- `packaging/linux/net.odamex.Odamex.Client.desktop` → `net.novadoom.NovaDoom.Client.desktop`
  - `Name=Odamex` → `Name=NovaDoom`
  - `Icon=net.odamex.Odamex.Client` → `Icon=net.novadoom.NovaDoom.Client`
  - `Exec=odamex` → `Exec=novadoom`
  - `MimeType=x-scheme-handler/odamex` → `x-scheme-handler/novadoom`
  - `StartupWMClass=odamex` → `StartupWMClass=novadoom`

- `packaging/linux/net.odamex.Odamex.Server.desktop` → `net.novadoom.NovaDoom.Server.desktop`
  - Similar changes for server

- `packaging/linux/net.odamex.Odamex.Launcher.desktop` → `net.novadoom.NovaDoom.Launcher.desktop`
  - Similar changes for launcher

- `installer/arch/odamex.desktop` → `novadoom.desktop`
  - `Name=Odamex` → `Name=NovaDoom`
  - `Exec=odamex` → `Exec=novadoom`
  - `Icon=odamex` → `Icon=novadoom`

**AppStream Metadata:** `packaging/linux/net.odamex.Odamex.metainfo.xml` → `net.novadoom.NovaDoom.metainfo.xml`
- Line 7: `<id>net.odamex.Odamex</id>` → `<id>net.novadoom.NovaDoom</id>`
- Line 8: `<name>Odamex</name>` → `<name>NovaDoom</name>`
- Line 10: `<id>net.odamex</id>` → `<id>net.novadoom</id>`
- Line 11: `<name>The Odamex Team</name>` → `<name>The NovaDoom Team</name>`
- Line 13-16: Update all URLs to NovaDoom
- Line 68: `flatpak override net.odamex.Odamex` → `net.novadoom.NovaDoom`

**Flatpak Manifest:** `packaging/flatpak/net.odamex.Odamex.yml` → `net.novadoom.NovaDoom.yml`
- Line 3: `app-id: net.odamex.Odamex` → `app-id: net.novadoom.NovaDoom`
- Line 16: `--filesystem=~/.odamex:create` → `--filesystem=~/.novadoom:create`
- Throughout: All references to executables

---

## Priority 2: Icons & Assets

### Icons to Replace

Use icons from `icons/` folder to create:

| Target File | Source |
|-------------|--------|
| `client/sdl/odamex.ico` → `novadoom.ico` | Create .ico from ND_*.png |
| `media/odamex.icns` → `novadoom.icns` | Create .icns from ND_*.png |
| `media/icon_odamex_512.png` | `icons/ND_512.png` |
| `media/icon_odamex_256.png` | `icons/ND_256.png` |
| `media/icon_odamex_128.png` | `icons/ND_128.png` |
| `media/icon_odamex_96.png` | Resize from ND_128.png |
| `media/odasrv.icns` → `novasrv.icns` | Create .icns (can use same icon) |
| `media/icon_odasrv_*.png` | Copy/adapt from ND_*.png |
| `media/odalaunch.icns` → `novalaunch.icns` | Create .icns |
| `media/icon_odalaunch_*.png` | Copy/adapt from ND_*.png |
| `odalaunch/res/odalaunch.icns` | Copy from media/ |
| `ag-odalaunch/res/odalaunch.icns` | Copy from media/ |
| `client/switch/assets/odamex.jpg` → `novadoom.jpg` | Create from ND_512.png |

### Embedded Icon in Code

- `client/gui/icon_odamex_128.png.cpp` - Regenerate with new icon
- `client/fluid/icon_odamex_128.png` - Replace with new icon

---

## Priority 3: URLs to Update

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

## Priority 4: CMake Configuration

### Main CMakeLists.txt

| Line | Change |
|------|--------|
| 17 | `project(Odamex VERSION 12.0.0)` → `project(NovaDoom VERSION 1.0.0)` |
| 26 | `ODAMEX_NO_GITVER` → `NOVADOOM_NO_GITVER` |
| 28 | `-DODAMEX_NO_GITVER` → `-DNOVADOOM_NO_GITVER` |
| 53 | `ODAMEX_INSTALL_BINDIR` → `NOVADOOM_INSTALL_BINDIR` |
| 54 | `ODAMEX_INSTALL_DATADIR` → `NOVADOOM_INSTALL_DATADIR` |
| 71-77 | Update all `ODAMEX_*` definitions |
| 82 | `PROJECT_COMPANY "The Odamex Team"` → `"The NovaDoom Team"` |
| 216 | `CPACK_PACKAGE_INSTALL_DIRECTORY Odamex` → `NovaDoom` |
| 221 | `CPACK_COMPONENT_CLIENT_DISPLAY_NAME "Odamex"` → `"NovaDoom"` |
| 223 | `"Odamex Dedicated Server"` → `"NovaDoom Dedicated Server"` |
| 225 | `"Odalaunch Odamex Server Browser..."` → `"NovaDoom Launcher..."` |
| 241, 244 | `odamex` directory → `novadoom` |
| 262 | `CPACK_PACKAGE_VENDOR` → `"NovaDoom Team"` |
| 267 | `CPACK_DEBIAN_PACKAGE_HOMEPAGE` → Your URL |

### Target CMakeLists

**Client:** `client/CMakeLists.txt`
- Executable name `odamex` → `novadoom`

**Server:** `server/CMakeLists.txt`
- Line 40: `add_executable(odasrv ...)` → `add_executable(novasrv ...)`
- Line 97: Error message update

**Launcher:** `odalaunch/CMakeLists.txt`
- Line 55: `add_executable(odalaunch ...)` → `add_executable(novalaunch ...)`

**WAD:** `wad/CMakeLists.txt`
- Lines 49, 55, 56: `odamex.wad` → `novadoom.wad`

---

## Priority 5: Internal Code (Lower Priority)

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

## Files to Rename

| Current Path | New Path |
|--------------|----------|
| `wad/odamex.wad` | `wad/novadoom.wad` |
| `client/sdl/odamex.ico` | `client/sdl/novadoom.ico` |
| `media/odamex.icns` | `media/novadoom.icns` |
| `media/odasrv.icns` | `media/novasrv.icns` |
| `media/odalaunch.icns` | `media/novalaunch.icns` |
| `media/icon_odamex_*.png` | `media/icon_novadoom_*.png` |
| `media/icon_odasrv_*.png` | `media/icon_novasrv_*.png` |
| `media/icon_odalaunch_*.png` | `media/icon_novalaunch_*.png` |
| `installer/windows/odamex.iss` | `installer/windows/novadoom.iss` |
| `installer/arch/odamex.desktop` | `installer/arch/novadoom.desktop` |
| `packaging/linux/net.odamex.Odamex.*.desktop` | `packaging/linux/net.novadoom.NovaDoom.*.desktop` |
| `packaging/linux/net.odamex.Odamex.metainfo.xml` | `packaging/linux/net.novadoom.NovaDoom.metainfo.xml` |
| `packaging/flatpak/net.odamex.Odamex.yml` | `packaging/flatpak/net.novadoom.NovaDoom.yml` |

---

## Workflow Already Updated

The GitHub Actions workflow (`.github/workflows/novadoom-release.yml`) already:
- Names the release "NovaDoom"
- Renames executables to `novadoom.exe` / `novasrv.exe` / `novasrv`
- Creates `NovaDoom.app` bundle
- Uses `wad/odamex.wad` (will need update after WAD rename)

---

## Recommended Implementation Order

1. **README.md** - Rewrite for NovaDoom
2. **Core version/branding** - `CMakeLists.txt`, `version.h`, `version.cpp`
3. **WAD file** - Rename `odamex.wad` → `novadoom.wad`
4. **Icons** - Generate .ico/.icns from new PNG icons
5. **Windows resources** - Update .rc.in files
6. **macOS bundles** - Update plists and CMake bundle settings
7. **Linux packaging** - Update desktop files, metainfo, flatpak
8. **Windows installer** - Update .iss file
9. **GitHub workflow** - Update WAD reference
10. **Copyright headers** - Script to update all source files
