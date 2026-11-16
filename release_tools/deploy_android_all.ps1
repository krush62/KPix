$apkSourcePath = "..\build\app\outputs\flutter-apk\app-release.apk"
$bundleSourcePath = "..\build\app\outputs\bundle\release\app-release.aab"
$yamlFile = "..\pubspec.yaml"
$versionLine = Select-String -Path $yamlFile -Pattern "version: (\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }
$versionCode = ($versionLine -replace '\.')
$versionCode = [int]$versionCode
$androidApkOutputPath = "AndroidAPK"
$androidBundleOutputPath = "AndroidBundle"
$gradleFilePath = "..\android\app\build.gradle"
$namespace = Select-String -Path $gradleFilePath -Pattern 'namespace =? ?"([^"]+)"' | ForEach-Object { $_.Matches.Groups[1].Value }

Write-Host "Extracted Version: $versionLine"
Write-Host "Version Code: $versionCode"
Write-Host "Extracted Namespace: $namespace"

Write-Host "Updating Gradle File"
$gradleContent = Get-Content $gradleFilePath
$gradleContent = $gradleContent -replace "flutterVersionName = '.*'", "flutterVersionName = '$versionLine'"
$gradleContent = $gradleContent -replace "flutterVersionCode = '.*'", "flutterVersionCode = '$versionCode'"
Set-Content -Path $gradleFilePath -Value $gradleContent


# flutter build picks a JDK new enough for release lint (21+), plain gradlew uses JAVA_HOME
# apkanalyzer.bat (used by the appbundle check) breaks on spaces in the SDK path, so pass the 8.3 short path
if (-Not $env:ANDROID_HOME) {
	$defaultSdk = "$env:LOCALAPPDATA\Android\sdk"
	if (Test-Path $defaultSdk) {
		$env:ANDROID_HOME = (New-Object -ComObject Scripting.FileSystemObject).GetFolder($defaultSdk).ShortPath
	}
}
Set-Location ..
Write-Host "Building APK..."
flutter build apk --release
if ($LASTEXITCODE -ne 0) { Set-Location $PSScriptRoot; Write-Host "APK build failed."; exit 1 }
Write-Host "Building Bundle..."
flutter build appbundle --release
if ($LASTEXITCODE -ne 0) { Set-Location $PSScriptRoot; Write-Host "Bundle build failed."; exit 1 }


Set-Location $PSScriptRoot


Write-Host "Copying APK..."
if (-Not (Test-Path -Path $androidApkOutputPath)) {		
	New-Item -Path ".\" -Name $androidApkOutputPath -ItemType "directory" | Out-Null
}
$fullApkPath = "$androidApkOutputPath\KPix-$versionLine.apk"
Copy-Item $apkSourcePath -Destination $fullApkPath


Write-Host "Copying Bundle..."
if (-Not (Test-Path -Path $androidBundleOutputPath)) {		
	New-Item -Path ".\" -Name $androidBundleOutputPath -ItemType "directory" | Out-Null
}
$fullBundlePath = "$androidBundleOutputPath\KPix-$versionLine.aab"
Copy-Item $bundleSourcePath -Destination $fullBundlePath

C:\Windows\explorer.exe "/select,`"$fullApkPath"`"
C:\Windows\explorer.exe "/select,`"$fullBundlePath"`"