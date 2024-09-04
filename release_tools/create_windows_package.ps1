$buildPath = "..\build\windows\x64\runner\Release"
$sourceFile = "..\pubspec.yaml"
$winPackagePath = "WinPackage"

# Extract the version number from the source file
$versionLine = Select-String -Path $sourceFile -Pattern "version: (\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }

if ($versionLine) {
    Write-Host "Extracted version: $versionLine"
	if (-Not (Test-Path -Path $winPackagePath)) {		
		New-Item -Path ".\" -Name $winPackagePath -ItemType "directory" | Out-Null
	}
	$packagePath = "$winPackagePath\kpix-windows-x64-v$versionLine"
	if (Test-Path -Path $packagePath) {
		Remove-Item -LiteralPath $packagePath -Force -Recurse
	}
	New-Item -Path ".\" -Name $packagePath -ItemType "directory" | Out-Null
	Copy-Item $buildPath\*.dll -Destination $packagePath
	Copy-Item $buildPath\kpix.exe -Destination $packagePath
	Copy-Item -Path $buildPath\data -Destination $packagePath -Recurse
	Compress-Archive -Path $packagePath -DestinationPath "$packagePath.zip"
    Remove-Item -LiteralPath $packagePath -Force -Recurse
	
} else {
    Write-Host "No version number found in the source file."
}

