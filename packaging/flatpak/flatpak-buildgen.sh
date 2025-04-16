#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/

# Exit if any command fails
set -e

# Echo all commands for debug purposes
set -x

# Untar deutex to wad directory
tar --zstd -xvf deutex-5.2.2.tar.zst -C wad/

# Untar wxWidgets to libraries directory
tar -xvf wxWidgets-3.0.5.tar.bz2 -C libraries/

mkdir -p build && cd build
# Generate build
cmake .. -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_OR_FAIL=1 -DBUILD_CLIENT=1 -DBUILD_SERVER=1 \
    -DBUILD_MASTER=0 -DBUILD_LAUNCHER=1 -DUSE_INTERNAL_LIBS=1 \
    -DUSE_INTERNAL_WXWIDGETS=1 -DUSE_INTERNAL_DEUTEX=1 \
    -DODAMEX_INSTALL_BINDIR=/app/bin -DODAMEX_INSTALL_DATADIR=/run/host/usr/share \
    -DUSE_EXTERNAL_LIBDWARF=1 -DODAMEX_NO_GITVER=$IS_FLATHUB

ninja odamex
ninja odasrv

# Copy wxWidgets dependencies into lib
# Before running wxrc
mkdir -p /app/lib
cp -r libraries/wxWidgets-3.0.5/lib/*.so /app/lib/
cp -r libraries/wxWidgets-3.0.5/lib/*.0 /app/lib/

ninja odalaunch

cd ..

# Assemble Flatpak assets

# Install timidity config
mkdir -p /app/etc
cp -r packaging/flatpak/timidity.cfg /app/etc/timidity.cfg

# Install the AppStream metadata file.
projectId=net.odamex.Odamex
metadataDir=/app/share/metainfo
mkdir -p $metadataDir
cp -r packaging/linux/$projectId.metainfo.xml $metadataDir/

# Install the odd demo filetype
iconDir=/app/share/icons/hicolor/512x512/mimetypes
mkdir -p $iconDir
cp -r ./media/icon_odademo_512.png $iconDir/$projectId-application-odamex-demo.png
mimeDir=/app/share/mime/packages/
mkdir -p $mimeDir
cp -r packaging/linux/$projectId-mime.xml $mimeDir/$projectId-mime.xml

# Install odamex.wad
mkdir -p /app/bin
cp -r build/wad/odamex.wad /app/bin/

# Client app
projectName=Odamex.Client
projectId=net.odamex.Odamex.Client
executableName=odamex

# Copy the client app to the Flatpak-based location.
mkdir -p /app/$projectName
install -c build/client/$executableName /app/$projectName/$executableName
ln -s /app/bin/odamex.wad /app/$projectName/odamex.wad
ln -s /app/$projectName/$executableName /app/bin/$executableName

# Install the icon.
iconDir=/app/share/icons/hicolor/512x512/apps
mkdir -p $iconDir
cp -r ./media/icon_odamex_512.png $iconDir/$projectId.png

# Install the desktop file.
desktopFileDir=/app/share/applications
mkdir -p $desktopFileDir
cp -r packaging/linux/$projectId.desktop $desktopFileDir/

# Server app
projectName=Odamex.Server
projectId=net.odamex.Odamex.Server
executableName=odasrv

# Copy the server app to the Flatpak-based location.
mkdir -p /app/$projectName
install -c build/server/$executableName /app/$projectName/$executableName
mkdir -p /app/bin
ln -s /app/bin/odamex.wad /app/$projectName/odamex.wad
ln -s /app/$projectName/$executableName /app/bin/$executableName

# Copy config samples into the flatpak
cp -r config-samples /app/$projectName/

# Install the icon.
iconDir=/app/share/icons/hicolor/512x512/apps
mkdir -p $iconDir
cp -r ./media/icon_odasrv_512.png $iconDir/$projectId.png

# Install the desktop file.
desktopFileDir=/app/share/applications
mkdir -p $desktopFileDir
cp -r packaging/linux/$projectId.desktop $desktopFileDir/

# Launcher app
projectName=Odamex.Launcher
projectId=net.odamex.Odamex.Launcher
executableName=odalaunch

# Copy the launcher app to the Flatpak-based location.
mkdir -p /app/$projectName
install -c build/odalaunch/$executableName /app/$projectName/$executableName
mkdir -p /app/bin
ln -s /app/$projectName/$executableName /app/bin/$executableName

# Install the icon.
iconDir=/app/share/icons/hicolor/512x512/apps
mkdir -p $iconDir
cp -r ./media/icon_odalaunch_512.png $iconDir/$projectId.png

# Install the desktop file.
desktopFileDir=/app/share/applications
mkdir -p $desktopFileDir
cp -r packaging/linux/$projectId.desktop $desktopFileDir/

# Install helper script
install -c packaging/flatpak/select-exe.sh /app/bin/select-exe
