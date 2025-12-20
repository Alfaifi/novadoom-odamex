#!/usr/bin/env bash

# Set the working directory to the NovaDoom installation dir. This is so it can find its own files,
# like novadoom.wad, etc.
cd "INSTALL_DIR"
exec "INSTALL_DIR/novasrv" "$@"
