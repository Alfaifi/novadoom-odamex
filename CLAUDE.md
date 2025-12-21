# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NovaDoom is a client/server multiplayer source port of DOOM, based on CSDoom 0.62 (itself based on ZDoom 1.22). The codebase is C++ targeting CMake 3.13+.

## Build Commands

```bash
# Clone with submodules (required)
git clone https://github.com/Alfaifi/novadoom-odamex.git --recurse-submodules

# Standard build (creates client, server, and launcher)
mkdir build && cd build
cmake ..
cmake --build .

# Build specific targets only
cmake .. -DBUILD_CLIENT=1 -DBUILD_SERVER=0 -DBUILD_LAUNCHER=0

# Release build with debug info (default)
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo

# Debug build
cmake .. -DCMAKE_BUILD_TYPE=Debug
```

**Build targets:**

- `novadoom` - Game client
- `novasrv` - Dedicated server
- `novalaunch` - Server browser/launcher (requires wxWidgets)
- `novadoomwad` - Resource WAD (requires DeuTex)

**Dependencies:** SDL2, SDL2_mixer, wxWidgets (launcher only), DeuTex (WAD building only). On Windows, libraries auto-download. On Linux/macOS, install via package manager.

## Architecture

```
client/     - Game client (rendering, input, audio, network client)
  src/      - Client-specific game logic (cl_*.cpp)
  sdl/      - SDL platform layer (i_*.cpp)
  gui/      - FLTK-based boot GUI
server/     - Dedicated server (sv_*.cpp)
common/     - Shared code between client/server
  p_*.cpp   - Playsim (physics, AI, map logic)
  g_*.cpp   - Game state, level management
  d_*.cpp   - Doom-specific systems
  m_*.cpp   - Miscellaneous utilities
  w_*.cpp   - WAD file handling
  i_net.*   - Network abstraction
odalaunch/  - wxWidgets server browser
odalpapi/   - Server query API (used by odalaunch)
odaproto/   - Protocol buffer definitions
libraries/  - Third-party libraries (submodules + bundled)
wad/        - odamex.wad resource files
tests/      - Tcl-based regression tests
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
- Include GPL header in new files

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

The project also has demo playback tests for vanilla compatibility (requires encrypted IWADs, see README for setup).

## Platform Support

Primary: Windows, macOS, Linux
