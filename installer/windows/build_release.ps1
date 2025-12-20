#
# Copyright (C) 2020 Alex Mayfield.
#
# If you double-clicked on the script expecting to run it, you need to right
# click Run With Powershell instead.
#

#
# These parameters can and should be changed for new versions.
#

Set-Variable -Name "CurrentDir" -Value (Get-Location) # cd to the base novadoom git path before executing (this assumes you're running this script in this dir)

Set-Variable -Name "NovaDoomVersion" -Value "11.0.0"
Set-Variable -Name "NovaDoomTestSuffix" -Value "" # "-RC3"

#
# The actual script follows.
#

Set-Variable -Name "CommonDir" -Value "${CurrentDir}\OutCommon"
Set-Variable -Name "X64Dir" -Value "${CurrentDir}\OutX64"
Set-Variable -Name "X86Dir" -Value "${CurrentDir}\OutX86"
Set-Variable -Name "OutputDir" -Value "${CurrentDir}\Output"

function BuildX64 {
    if (Test-Path "${CurrentDir}\BuildX64")
    {
        Remove-Item -Recurse -Path "${CurrentDir}\BuildX64"
    }
    New-Item  -Force -ItemType "directory" -Path "${CurrentDir}\BuildX64"
    Set-Location -Path "${CurrentDir}\BuildX64"

    cmake.exe -G "Visual Studio 17 2022" -A "x64" "${CurrentDir}" `
        -DBUILD_OR_FAIL=1 `
        -DBUILD_CLIENT=1 -DBUILD_SERVER=1 `
        -DBUILD_MASTER=1 -DBUILD_LAUNCHER=1
    cmake.exe --build . --config RelWithDebInfo

    Set-Location -Path "${CurrentDir}"
}

function BuildX86 {
    if (Test-Path "${CurrentDir}\BuildX86")
    {
        Remove-Item -Recurse -Path "${CurrentDir}\BuildX86"
    }
    New-Item  -Force -ItemType "directory" -Path "${CurrentDir}\BuildX86"
    Set-Location -Path "${CurrentDir}\BuildX86"

    cmake.exe -G "Visual Studio 17 2022" -A "Win32" "${CurrentDir}" `
        -DBUILD_OR_FAIL=1 `
        -DBUILD_CLIENT=1 -DBUILD_SERVER=1 `
        -DBUILD_MASTER=1 -DBUILD_LAUNCHER=1
    cmake.exe --build . --config RelWithDebInfo

    Set-Location -Path "${CurrentDir}"
}

function CopyFiles {
    if (Test-Path "${CommonDir}")
    {
        Remove-Item -Force -Recurse -Path "${CommonDir}"
    }

    if (Test-Path "${X64Dir}")
    {
        Remove-Item -Force -Recurse -Path "${X64Dir}"
    }

    if (Test-Path "${X86Dir}")
    {
        Remove-Item -Force -Recurse -Path "${X86Dir}"
    }

    New-Item -Force -ItemType "directory" -Path "${CommonDir}"
    New-Item -Force -ItemType "directory" -Path "${CommonDir}\config-samples"
    New-Item -Force -ItemType "directory" -Path "${CommonDir}\licenses"

    Copy-Item -Force -Path "${CurrentDir}\3RD-PARTY-LICENSES" `
        -Destination "${CommonDir}\3RD-PARTY-LICENSES.txt"
    Copy-Item -Force -Path "${CurrentDir}\CHANGELOG" `
        -Destination "${CommonDir}\CHANGELOG.txt"
    Copy-Item -Force -Path "${CurrentDir}\novadoom-installed.txt" `
        -Destination "${CommonDir}"
    Copy-Item -Force -Path "${CurrentDir}\config-samples\*" `
        -Destination "${CommonDir}\config-samples"
    Copy-Item -Force -Path "${CurrentDir}\libraries\curl\COPYING" `
        -Destination "${CommonDir}\licenses\COPYING.curl.txt"
    Copy-Item -Force -Path "${CurrentDir}\libraries\miniupnp\LICENSE" `
        -Destination "${CommonDir}\licenses\LICENSE.miniupnp.txt"
    Copy-Item -Force -Path "${CurrentDir}\libraries\libpng\LICENSE" `
        -Destination "${CommonDir}\licenses\LICENSE.libpng.txt"
    Copy-Item -Force -Path "${CurrentDir}\libraries\portmidi\license.txt" `
        -Destination "${CommonDir}\licenses\license.portmidi.txt"
    Copy-Item -Force -Path "${CurrentDir}\LICENSE" `
        -Destination "${CommonDir}\LICENSE.txt"
    Copy-Item -Force -Path "${CurrentDir}\MAINTAINERS" `
        -Destination "${CommonDir}\MAINTAINERS.txt"
    Copy-Item -Force -Path "${CurrentDir}\README" `
        -Destination "${CommonDir}\README.txt"
    Copy-Item -Force -Path "${CurrentDir}\BuildX64\wad\novadoom.wad" `
        -Destination "${CommonDir}"
    Copy-Item -Force -Path "${CurrentDir}\BuildX64\libraries\SDL2_mixer-2.8.1\LICENSE.txt" `
        -Destination "${CommonDir}\licenses\COPYING.SDL2_mixer.txt"
    Copy-Item -Force -Path "${CurrentDir}\BuildX64\libraries\SDL2_mixer-2.8.1\lib\x64\optional\LICENSE.xmp.txt" `
        -Destination "${CommonDir}\licenses"
    Copy-Item -Force -Path "${CurrentDir}\BuildX64\libraries\SDL2_mixer-2.8.1\lib\x64\optional\LICENSE.ogg-vorbis.txt" `
        -Destination "${CommonDir}\licenses"
    Copy-Item -Force -Path "${CurrentDir}\BuildX64\libraries\SDL2_mixer-2.8.1\lib\x64\optional\LICENSE.opus.txt" `
        -Destination "${CommonDir}\licenses"
    Copy-Item -Force -Path "${CurrentDir}\BuildX64\libraries\SDL2_mixer-2.8.1\lib\x64\optional\LICENSE.opusfile.txt" `
        -Destination "${CommonDir}\licenses"
    Copy-Item -Force -Path "${CurrentDir}\BuildX64\libraries\SDL2_mixer-2.8.1\lib\x64\optional\LICENSE.wavpack.txt" `
        -Destination "${CommonDir}\licenses"
    Copy-Item -Force -Path "${CurrentDir}\BuildX64\libraries\SDL2_mixer-2.8.1\lib\x64\optional\LICENSE.gme.txt" `
        -Destination "${CommonDir}\licenses"
    Copy-Item -Force -Path "${CurrentDir}\BuildX64\libraries\SDL2-2.32.8\LICENSE.txt" `
        -Destination "${CommonDir}\licenses\LICENSE.SDL2.txt"

    ########################################
    ## 64-BIT FILES
    ########################################

    New-Item -Force -ItemType "directory" -Path "${X64Dir}"
    New-Item -Force -ItemType "directory" -Path "${X64Dir}/redist"

    Copy-Item -Force -Path `
        "${CurrentDir}\BuildX64\client\RelWithDebInfo\libgme.dll", `
        "${CurrentDir}\BuildX64\client\RelWithDebInfo\libwavpack-1.dll", `
        "${CurrentDir}\BuildX64\client\RelWithDebInfo\libxmp.dll", `
        "${CurrentDir}\BuildX64\client\RelWithDebInfo\libogg-0.dll", `
        "${CurrentDir}\BuildX64\client\RelWithDebInfo\libopus-0.dll", `
        "${CurrentDir}\BuildX64\client\RelWithDebInfo\libopusfile-0.dll", `
        "${CurrentDir}\BuildX64\client\RelWithDebInfo\novadoom.exe", `
        "${CurrentDir}\BuildX64\client\RelWithDebInfo\SDL2_mixer.dll", `
        "${CurrentDir}\BuildX64\client\RelWithDebInfo\SDL2.dll", `
        "${CurrentDir}\BuildX64\odalaunch\RelWithDebInfo\novalaunch.exe", `
        "${CurrentDir}\BuildX64\odalaunch\RelWithDebInfo\wxbase315u_net_vc14x_x64.dll", `
        "${CurrentDir}\BuildX64\odalaunch\RelWithDebInfo\wxbase315u_vc14x_x64.dll", `
        "${CurrentDir}\BuildX64\odalaunch\RelWithDebInfo\wxbase315u_xml_vc14x_x64.dll", `
        "${CurrentDir}\BuildX64\odalaunch\RelWithDebInfo\wxmsw315u_core_vc14x_x64.dll", `
        "${CurrentDir}\BuildX64\odalaunch\RelWithDebInfo\wxmsw315u_html_vc14x_x64.dll", `
        "${CurrentDir}\BuildX64\odalaunch\RelWithDebInfo\wxmsw315u_xrc_vc14x_x64.dll", `
        "${CurrentDir}\BuildX64\server\RelWithDebInfo\novasrv.exe" `
        -Destination "${X64Dir}\"

    # Get VC++ Redist
    Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile "${X64Dir}\redist\vc_redist.x64.exe"

    ########################################
    ## 32-BIT FILES
    ########################################

    New-Item -Force -ItemType "directory" -Path "${X86Dir}"
    New-Item -Force -ItemType "directory" -Path "${X86Dir}/redist"

    Copy-Item -Force -Path `
        "${CurrentDir}\BuildX86\client\RelWithDebInfo\libwavpack-1.dll", `
        "${CurrentDir}\BuildX86\client\RelWithDebInfo\libgme.dll", `
        "${CurrentDir}\BuildX86\client\RelWithDebInfo\libxmp.dll", `
        "${CurrentDir}\BuildX86\client\RelWithDebInfo\libogg-0.dll", `
        "${CurrentDir}\BuildX86\client\RelWithDebInfo\libopus-0.dll", `
        "${CurrentDir}\BuildX86\client\RelWithDebInfo\libopusfile-0.dll", `
        "${CurrentDir}\BuildX86\client\RelWithDebInfo\novadoom.exe", `
        "${CurrentDir}\BuildX86\client\RelWithDebInfo\SDL2_mixer.dll", `
        "${CurrentDir}\BuildX86\client\RelWithDebInfo\SDL2.dll", `
        "${CurrentDir}\BuildX86\odalaunch\RelWithDebInfo\novalaunch.exe", `
        "${CurrentDir}\BuildX86\odalaunch\RelWithDebInfo\wxbase315u_net_vc14x.dll", `
        "${CurrentDir}\BuildX86\odalaunch\RelWithDebInfo\wxbase315u_vc14x.dll", `
        "${CurrentDir}\BuildX86\odalaunch\RelWithDebInfo\wxbase315u_xml_vc14x.dll", `
        "${CurrentDir}\BuildX86\odalaunch\RelWithDebInfo\wxmsw315u_core_vc14x.dll", `
        "${CurrentDir}\BuildX86\odalaunch\RelWithDebInfo\wxmsw315u_html_vc14x.dll", `
        "${CurrentDir}\BuildX86\odalaunch\RelWithDebInfo\wxmsw315u_xrc_vc14x.dll", `
        "${CurrentDir}\BuildX86\server\RelWithDebInfo\novasrv.exe" `
        -Destination "${X86Dir}\"

    # Get VC++ Redist
    Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x86.exe" -OutFile "${X86Dir}\redist\vc_redist.x86.exe"
}

function Outputs {
    if (Test-Path "${OutputDir}")
    {
        Remove-Item -Force -Recurse -Path "${OutputDir}"
    }
    New-Item  -Force -ItemType "directory" -Path "${OutputDir}"

    # Generate archives
    7z.exe a `
        "${OutputDir}\novadoom-win64-${NovaDoomVersion}${NovaDoomTestSuffix}.zip" `
        "${CommonDir}\*" "${X64Dir}\*" `
        "-x!${CommonDir}\novadoom-installed.txt"
    7z.exe a `
        "${OutputDir}\novadoom-win32-${NovaDoomVersion}${NovaDoomTestSuffix}.zip" `
        "${CommonDir}\*" "${X86Dir}\*" `
        "-x!${CommonDir}\novadoom-installed.txt"

    # Generate installer
    ISCC.exe "${CurrentDir}\installer\windows\novadoom.iss" `
        /DNovaDoomVersion=${NovaDoomVersion} `
        /DNovaDoomTestSuffix=${NovaDoomTestSuffix} `
        /DSourcePath=${CurrentDir} `
        /O${OutputDir}
}

function ZipDebug {
    # Copy pdb files into zip.  DO NOT THROW THESE AWAY!
    Copy-Item -Force -Path `
        "${CurrentDir}\BuildX64\client\RelWithDebInfo\novadoom.pdb" `
        -Destination "${OutputDir}\novadoom-x64-${NovaDoomVersion}.pdb"
    Copy-Item -Force -Path `
        "${CurrentDir}\BuildX64\server\RelWithDebInfo\novasrv.pdb" `
        -Destination "${OutputDir}\novasrv-x64-${NovaDoomVersion}.pdb"
    Copy-Item -Force -Path `
        "${CurrentDir}\BuildX64\odalaunch\RelWithDebInfo\novalaunch.pdb" `
        -Destination "${OutputDir}\novalaunch-x64-${NovaDoomVersion}.pdb"

    Copy-Item -Force -Path `
        "${CurrentDir}\BuildX86\client\RelWithDebInfo\novadoom.pdb" `
        -Destination "${OutputDir}\novadoom-x86-${NovaDoomVersion}.pdb"
    Copy-Item -Force -Path `
        "${CurrentDir}\BuildX86\server\RelWithDebInfo\novasrv.pdb" `
        -Destination "${OutputDir}\novasrv-x86-${NovaDoomVersion}.pdb"
    Copy-Item -Force -Path `
        "${CurrentDir}\BuildX86\odalaunch\RelWithDebInfo\novalaunch.pdb" `
        -Destination "${OutputDir}\novalaunch-x86-${NovaDoomVersion}.pdb"

    7z.exe a `
        "${OutputDir}\novadoom-debug-pdb-${NovaDoomVersion}.zip" `
        "${OutputDir}\*.pdb"

    Remove-Item -Force -Path "${OutputDir}\*.pdb"
}

# Ensure we have the proper executables in the PATH
echo "Checking for CMake..."
Get-Command cmake.exe -ErrorAction Stop

echo "Checking for 7zip..."
Get-Command 7z.exe -ErrorAction Stop

echo "Checking for Inno Setup Command-Line Compiler..."
Get-Command ISCC.exe -ErrorAction Stop

echo "Building 64-bit..."
BuildX64

echo "Building 32-bit..."
BuildX86

echo "Copying files..."
CopyFiles

echo "Generating output..."
Outputs

echo "Copying PDB's into ZIP..."
ZipDebug
