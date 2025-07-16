$vsRedistDir = "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Redist\MSVC\14.38.33135\x64\Microsoft.VC143.CRT"
#$vsRedistDir = "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Redist\MSVC\14.42.34433\x64\Microsoft.VC143.CRT"
$buildPath = "..\build\windows\x64\runner\Release"

# Build KPix for Windows
cd ..
flutter build windows --release
cd $PSScriptRoot

# Copying redist dll files
Copy-Item $vsRedistDir\msvcp140.dll -Destination $buildPath
Copy-Item $vsRedistDir\msvcp140_1.dll -Destination $buildPath
Copy-Item $vsRedistDir\msvcp140_2.dll -Destination $buildPath
Copy-Item $vsRedistDir\vcruntime140.dll -Destination $buildPath
Copy-Item $vsRedistDir\vcruntime140_1.dll -Destination $buildPath
