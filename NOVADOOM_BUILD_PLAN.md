# NovaDoom Binary Distribution Plan

## Overview

This document outlines the plan to build and distribute custom Odamex binaries for the NovaDoom platform, with FluidSynth integration and GZDoom-matching audio configuration.

---

## Target Binaries

| Binary         | Platform                         | Purpose                       | Bundle Contents                      |
| -------------- | -------------------------------- | ----------------------------- | ------------------------------------ |
| `NovaDoom.app` | macOS Universal (ARM64 + x86_64) | Client for Mac players        | FluidSynth, SDL2, soundfont          |
| `NovaDoom.exe` | Windows x64                      | Client for Windows players    | FluidSynth DLL, SDL2 DLLs, soundfont |
| `novasrv`      | Linux x86_64 (Ubuntu)            | Dedicated server for NovaDoom | Minimal deps, statically linked      |

---

## Repository Structure

```
novadoom-odamex/                    # Private fork of Odamex
├── .github/
│   └── workflows/
│       └── novadoom-release.yml    # Custom build workflow
├── soundfonts/
│   └── gzdoom.sf2                  # Bundled soundfont (~50MB)
├── ci/
│   ├── novadoom-macos.sh           # macOS build script
│   ├── novadoom-windows.ps1        # Windows build script
│   └── novadoom-linux-server.sh    # Linux server build script
├── ... (Odamex source with FluidSynth changes)
└── NOVADOOM_BUILD_PLAN.md          # This file
```

---

## GitHub Actions Workflow

### Triggers

- **Manual dispatch** (`workflow_dispatch`) with version input
- **Tag push** (e.g., `v1.0.0-novadoom`)

### Build Jobs

#### 1. macOS Universal Binary

```yaml
jobs:
  build-macos:
    strategy:
      matrix:
        include:
          - runner: macos-14 # ARM64 (M1/M2/M3)
            arch: arm64
          - runner: macos-13 # Intel x86_64
            arch: x86_64
    steps:
      - Install dependencies (brew: fluidsynth, sdl2, sdl2_mixer)
      - Configure CMake with FluidSynth enabled
      - Build odamex
      - Bundle soundfont into .app

  create-universal:
    needs: build-macos
    steps:
      - Download ARM64 and x86_64 builds
      - Create Universal Binary using lipo
      - Create DMG installer
      - Upload to GitHub Release
```

#### 2. Windows x64

```yaml
build-windows:
  runs-on: windows-latest
  steps:
    - Install vcpkg dependencies (fluidsynth, sdl2, sdl2-mixer)
    - Configure CMake with Visual Studio
    - Build novadoom (RelWithDebInfo)
    - Bundle DLLs and soundfont
    - Create ZIP archive
    - Upload to GitHub Release
```

#### 3. Linux Server (novasrv only)

```yaml
build-linux-server:
  runs-on: ubuntu-22.04
  steps:
    - Install minimal dependencies (no GUI, no audio)
    - Configure CMake with -DBUILD_CLIENT=OFF -DBUILD_SERVER=ON
    - Build novasrv
    - Strip binary for size
    - Create tar.gz archive
    - Upload to GitHub Release
```

---

## Build Configuration

### CMake Options

**Client Builds (macOS/Windows):**

```bash
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_FLUIDSYNTH=ON \
  -DBUILD_CLIENT=ON \
  -DBUILD_SERVER=ON \
  -DBUILD_MASTER=OFF
```

**Server Build (Linux):**

```bash
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_CLIENT=OFF \
  -DBUILD_SERVER=ON \
  -DBUILD_MASTER=OFF \
  -DENABLE_PORTMIDI=OFF \
  -DENABLE_FLUIDSYNTH=OFF
```

---

## Dependency Installation

### macOS (Homebrew)

```bash
brew install fluidsynth sdl2 sdl2_mixer libpng zlib
```

### Windows (vcpkg)

```powershell
vcpkg install fluidsynth:x64-windows sdl2:x64-windows sdl2-mixer:x64-windows
```

### Linux Server (apt)

```bash
# Minimal - no audio/video dependencies
sudo apt-get install build-essential cmake libcurl4-openssl-dev zlib1g-dev
```

---

## Artifact Bundling

### macOS .app Bundle

```
NovaDoom.app/
├── Contents/
│   ├── MacOS/
│   │   ├── novadoom              # Universal binary
│   │   ├── novasrv               # Server binary
│   │   ├── odamex.wad
│   │   └── soundfonts/
│   │       └── gzdoom.sf2
│   ├── Frameworks/
│   │   ├── libfluidsynth.dylib
│   │   ├── SDL2.framework/
│   │   └── SDL2_mixer.framework/
│   ├── Resources/
│   │   └── novadoom.icns
│   └── Info.plist
```

### Windows ZIP

```
NovaDoom-Win64/
├── novadoom.exe
├── novasrv.exe
├── odamex.wad
├── soundfonts/
│   └── gzdoom.sf2
├── fluidsynth.dll
├── SDL2.dll
├── SDL2_mixer.dll
└── vcruntime140.dll (if needed)
```

### Linux Server tar.gz

```
novadoom-server-linux-x64/
├── novasrv                # Statically linked server binary
└── README.txt
```

---

## Release Artifacts

Each release will produce:

| Artifact     | Filename                                     | Size (est.) |
| ------------ | -------------------------------------------- | ----------- |
| macOS DMG    | `NovaDoom-macOS-universal-{version}.dmg`     | ~80MB       |
| Windows ZIP  | `NovaDoom-Win64-{version}.zip`               | ~60MB       |
| Linux Server | `NovaDoom-Server-Linux-x64-{version}.tar.gz` | ~5MB        |

---

## Integration with NovaDoom Platform

### Current Setup

- Binary path: `/home/odamex/novadoom-server`
- Process user: `odamex`
- Port range: 10666-10676

### Deployment Steps

1. Download `NovaDoom-Server-Linux-x64-{version}.tar.gz` from release
2. Extract to `/home/odamex/`
3. Rename/symlink `novasrv` to `novadoom-server`
4. Set permissions: `chown odamex:odamex /home/odamex/novadoom-server`

### Future: Auto-Update (Phase 4+)

- Add version endpoint to NovaDoom backend
- Check GitHub Releases API for new versions
- Download and swap binary with zero-downtime

---

## Timeline

| Step | Task                                   | Status  |
| ---- | -------------------------------------- | ------- |
| 1    | Create `novadoom-release.yml` workflow | Pending |
| 2    | Create/modify CI build scripts         | Pending |
| 3    | Test macOS Universal build             | Pending |
| 4    | Test Windows build with FluidSynth     | Pending |
| 5    | Test Linux server build                | Pending |
| 6    | Create first release                   | Pending |
| 7    | Deploy to NovaDoom production          | Pending |

---

## Notes

- The soundfont (`gzdoom.sf2`, ~50MB) will be committed to the repository
- macOS builds require both `macos-13` (Intel) and `macos-14` (ARM) runners
- Windows builds use Visual Studio 2022 via `windows-latest`
- Linux server builds target Ubuntu 22.04 for compatibility

---

## Approval

- [ ] Plan reviewed and approved
- [ ] Repository created (`novadoom-odamex`)
- [ ] Proceed with implementation
