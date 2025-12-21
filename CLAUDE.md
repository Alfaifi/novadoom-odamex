# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NovaDoom is a client/server multiplayer source port of DOOM, forked from Odamex (which is based on ZDoom 1.22). It integrates with the NovaDoom Platform for web-based server management. The codebase is C++ targeting CMake 3.13+.

## Build Commands

```bash
# Clone with submodules (required)
git clone https://github.com/Alfaifi/novadoom-odamex.git --recurse-submodules

# Standard build (creates client and server)
mkdir build && cd build
cmake ..
cmake --build .

# Build specific targets only
cmake .. -DBUILD_CLIENT=1 -DBUILD_SERVER=0

# Debug build
cmake .. -DCMAKE_BUILD_TYPE=Debug

# Release build with debug info (default)
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
```

**Build targets:**

- `novadoom` - Game client
- `novasrv` - Dedicated server
- `novadoomwad` - Resource WAD (requires DeuTex)

**Dependencies:** SDL2, SDL2_mixer, DeuTex (WAD building only). On Windows, libraries auto-download. On Linux/macOS, install via package manager.

## Architecture

```
client/        - Game client
  src/         - Client game logic (cl_*.cpp)
  sdl/         - SDL platform layer (i_*.cpp)
  gui/         - FLTK-based boot GUI
server/        - Dedicated server (sv_*.cpp)
common/        - Shared code between client/server
  p_*.cpp      - Playsim (physics, AI, map logic)
  g_*.cpp      - Game state, level management
  d_*.cpp      - Doom-specific systems
  m_*.cpp      - Miscellaneous utilities
  w_*.cpp      - WAD file handling
odaproto/      - Protocol Buffers definitions (client/server network messages)
libraries/     - Third-party libraries (submodules + bundled)
wad/           - novadoom.wad resource files
tests/         - Tcl-based regression tests
novalaunch-tauri/ - Tauri-based launcher (loads novadoom.com)
```

**Key preprocessor defines:**

- `CLIENT_APP` - Client build
- `SERVER_APP` - Server build

## Code Style

Uses `.clang-format` (Microsoft style base, tabs for indentation, 90 column limit).

**Essential rules:**

- Use `nullptr` (not `NULL` or `0`)
- Use `std::string` over C-style strings
- Use C++ casts (`static_cast`, `const_cast`, `reinterpret_cast`)
- Allman brace style (braces on separate lines)
- Use `M_Malloc`/`M_Free` from `m_alloc.h` instead of standard C allocation
- Unix line endings (LF)
- Include GPL header in new files (with NovaDoom copyright)

**Avoid:**

- Preprocessor macros and global variables where possible
- Hungarian notation
- C-style casts and `goto`
- Magic numbers

## Testing

Tests use Tcl scripts in `tests/`:

```bash
cd tests
tclsh all.tcl        # Run all tests
tclsh all.tcl -html  # HTML report output
```

## Platform Support

Windows, macOS, Linux
