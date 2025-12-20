Set-PSDebug -Trace 1

Set-Location "build"
New-Item -Name "demotest" -ItemType "directory" | Out-Null

# Copy all built files into artifact directory
Copy-Item -Path `
    ".\client\RelWithDebInfo\novadoom.exe", `
    ".\client\RelWithDebInfo\novadoom.pdb", `
    ".\client\RelWithDebInfo\*.dll", `
    ".\server\RelWithDebInfo\novasrv.exe", `
    ".\server\RelWithDebInfo\novasrv.pdb", `
    ".\odalaunch\RelWithDebInfo\novalaunch.exe", `
    ".\odalaunch\RelWithDebInfo\novalaunch.pdb", `
    ".\odalaunch\RelWithDebInfo\*.dll", `
    ".\wad\novadoom.wad", `
    "C:\Windows\System32\msvcp140.dll", `
    "C:\Windows\System32\vcruntime140.dll", `
    "C:\Windows\System32\vcruntime140_1.dll" `
    -Destination "demotest"

Set-Location ..
