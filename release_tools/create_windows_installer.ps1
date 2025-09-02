$sourceFile = "..\pubspec.yaml"
$destinationFile = "windows_installer_build.iss"
$innoLocation = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

# Extract the version number from the source file
$versionLine = Select-String -Path $sourceFile -Pattern "version: (\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }

if ($versionLine) {
    Write-Host "Extracted version: $versionLine"

    # Read the destination file content
    $destinationContent = Get-Content -Path $destinationFile

    # Replace the version number in the destination file
    $updatedContent = $destinationContent -replace '#define MyAppVersion "(\d+\.\d+\.\d+)"', "#define MyAppVersion `"$versionLine`""

    # Write the updated content back to the destination file
    Set-Content -Path $destinationFile -Value $updatedContent

    Write-Host "Version number updated successfully."
	
	# Run Installer creation
	&$innoLocation /Qp $destinationFile

    $outputDir = "WinInstaller\KPix-Installer-$versionLine-x64.exe"

    # Open in Explorer
    C:\Windows\explorer.exe "/select,`"$outputDir"`"
	
} else {
    Write-Host "No version number found in the source file."
}