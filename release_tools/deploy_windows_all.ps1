Write-Host "Building Windows Release Version..."
.\build_windows.ps1
Write-Host "Creating Windows Installer..."
.\create_windows_installer.ps1
Write-Host "Creating Windows Package..."
.\create_windows_package.ps1