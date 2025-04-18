#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/

# Exit if any command fails
set -e

# Echo all commands for debug purposes
set -x

mkdir -p build && cd build
# Generate build
cmake .. -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_OR_FAIL=1 -DBUILD_CLIENT=1 -DBUILD_SERVER=1 \
    -DBUILD_MASTER=0 -DBUILD_LAUNCHER=1 -DUSE_INTERNAL_LIBS=1 \
    -DUSE_INTERNAL_DEUTEX=1 \
    -DODAMEX_INSTALL_BINDIR=/app/bin -DODAMEX_INSTALL_DATADIR=/run/host/usr/share \
    -DUSE_EXTERNAL_LIBDWARF=1 -DODAMEX_NO_GITVER=$IS_FLATHUB

ninja odamex
ninja odasrv


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
cp -r media/icon_odademo_512.png $iconDir/$projectId-application-odamex-demo.png
mimeDir=/app/share/mime/packages/
mkdir -p $mimeDir
cp -r packaging/linux/$projectId-mime.xml $mimeDir/$projectId-mime.xml

# Install odamex.wad
mkdir -p /app/bin
cp -r build/wad/odamex.wad /app/bin/

# Install the executables
install_executable() {
    local projectName=$1
    local projectId=$2
    local executableName=$3
    local buildFolder=$4

    # Copy the app to the Flatpak-based location.
    mkdir -p /app/$projectName
    install -c build/$buildFolder/$executableName /app/$projectName/$executableName
    ln -s /app/$projectName/$executableName /app/bin/$executableName

    # Install the icon.
    iconDir=/app/share/icons/hicolor/512x512/apps
    mkdir -p $iconDir
    cp -r media/icon_${executableName}_512.png $iconDir/$projectId.png

    # Install the desktop file.
    desktopFileDir=/app/share/applications
    mkdir -p $desktopFileDir
    cp -r packaging/linux/$projectId.desktop $desktopFileDir/
}

# Client app
install_executable Odamex.Client net.odamex.Odamex.Client odamex client
ln -s /app/bin/odamex.wad /app/Odamex.Client/odamex.wad

# Server app
install_executable Odamex.Server net.odamex.Odamex.Server odasrv server
ln -s /app/bin/odamex.wad /app/Odamex.Server/odamex.wad

# Launcher app
install_executable Odamex.Launcher net.odamex.Odamex.Launcher odalaunch odalaunch

# Copy config samples into the flatpak
cp -r config-samples /app/$projectName/

# Install helper script
install -c packaging/flatpak/select-exe.sh /app/bin/select-exe
