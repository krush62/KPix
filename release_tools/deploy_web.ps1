$pubspecPath = "..\pubspec.yaml"
$webPackagePath = "Web"
$buildPath = "..\build\web"

Write-Host "Building Web Release Version..."
.\build_web.ps1

$versionLine = Select-String -Path $pubspecPath -Pattern "version: (\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }
if ($versionLine) {
    Write-Host "Extracted version: $versionLine"
    if (-Not (Test-Path -Path $webPackagePath)) {
        New-Item -Path ".\" -Name $webPackagePath -ItemType "directory" | Out-Null
    }
    $packagePath = "$webPackagePath\kpix-web-v$versionLine"
    if (Test-Path -Path $packagePath) {
        Remove-Item -Recurse -Force $packagePath
    }
    New-Item -Path ".\" -Name $packagePath -ItemType "directory" | Out-Null
    Copy-item -Force -Recurse $buildPath\* -Destination $packagePath

} else {
    Write-Host "No version number found in the source file."
}