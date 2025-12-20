![NovaDoom](icons/ND_128.png)

# NovaDoom Client & Server

The official game client and dedicated server for the [NovaDoom Platform](https://novadoom.com) - a modern web-based management platform for DOOM multiplayer servers.

| Windows Build | macOS Build | Linux Build |
|---------------|-------------|-------------|
| [![Windows](https://github.com/Alfaifi/novadoom-odamex/actions/workflows/novadoom-release.yml/badge.svg)](https://github.com/Alfaifi/novadoom-odamex/actions/workflows/novadoom-release.yml) | [![macOS](https://github.com/Alfaifi/novadoom-odamex/actions/workflows/novadoom-release.yml/badge.svg)](https://github.com/Alfaifi/novadoom-odamex/actions/workflows/novadoom-release.yml) | [![Linux](https://github.com/Alfaifi/novadoom-odamex/actions/workflows/novadoom-release.yml/badge.svg)](https://github.com/Alfaifi/novadoom-odamex/actions/workflows/novadoom-release.yml) |

## About

NovaDoom is a modified version of [Odamex](https://github.com/odamex/odamex) - the open-source client/server DOOM source port. This fork is customized to integrate with the NovaDoom Platform, providing a seamless multiplayer experience managed through a modern web interface.

## Downloads

Pre-built binaries are available on the [Releases](https://github.com/Alfaifi/novadoom-odamex/releases) page:

| Component | Description |
|-----------|-------------|
| **NovaDoom** | Game client (Windows, macOS) |
| **NovaSrv** | Dedicated server (Windows, macOS, Linux) |

## Building from Source

```bash
git clone https://github.com/Alfaifi/novadoom-odamex.git --recurse-submodules
cd novadoom-odamex
mkdir build && cd build
cmake ..
cmake --build .
```

### Dependencies

* CMake 3.13+
* SDL2 and SDL2_mixer
* libPNG, zlib, cURL (included as submodules)

On Windows, dependencies are downloaded automatically. On Linux/macOS, install via package manager.

## License

NovaDoom is released under the GNU General Public License v2. See [LICENSE](LICENSE) for details.

## Credits

* **[Odamex Team](https://odamex.net)** - Original Odamex source port
* **Sergey Makovkin** - CSDoom 0.62
* **Marisa Heit** - ZDoom 1.22
* **id Software** - Original DOOM source code
