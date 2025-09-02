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
	$packagePath = "$winPackagePath\KPix-$versionLine-x86_x64"
	if (Test-Path -Path $packagePath) {
		Remove-Item -LiteralPath $packagePath -Force -Recurse
	}
	New-Item -Path ".\" -Name $packagePath -ItemType "directory" | Out-Null
	Copy-Item $buildPath\*.dll -Destination $packagePath
	Copy-Item $buildPath\kpix.exe -Destination $packagePath
	Copy-Item -Path $buildPath\data -Destination $packagePath -Recurse
	Compress-Archive -Path $packagePath -Force -DestinationPath "$packagePath.zip"
    Remove-Item -LiteralPath $packagePath -Force -Recurse

	# Open in Explorer
	C:\Windows\explorer.exe "/select,`"$packagePath.zip"`"
	
} else {
    Write-Host "No version number found in the source file."
}

