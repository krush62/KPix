$jarSigner = "C:\Program Files\Android\Android Studio\jbr\bin\jarsigner.exe"
$keyStore = "upload-keystore.jks"
$apkSourcePath = "..\build\app\outputs\flutter-apk\app-release.apk"
$bundleSourcePath = "..\build\app\outputs\bundle\release\app-release.aab"
$keyStoreAlias = "upload"
$yamlFile = "..\pubspec.yaml"
$versionLine = Select-String -Path $yamlFile -Pattern "version: (\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }
$versionCode = ($versionLine -replace '\.')
$versionCode = [int]$versionCode
$androidApkOutputPath = "AndroidAPK"
$androidBundleOutputPath = "AndroidBundle"
$gradleFilePath = "..\android\app\build.gradle"
$namespace = Select-String -Path $gradleFilePath -Pattern 'namespace "([^"]+)"' | ForEach-Object { $_.Matches.Groups[1].Value }

Write-Host "Extracted Version: $versionLine"
Write-Host "Version Code: $versionCode"
Write-Host "Extracted Namespace: $namespace"

Write-Host "Updating Gradle File"
$gradleContent = Get-Content $gradleFilePath
$gradleContent = $gradleContent -replace "flutterVersionName = '.*'", "flutterVersionName = '$versionLine'"
$gradleContent = $gradleContent -replace "flutterVersionCode = '.*'", "flutterVersionCode = '$versionCode'"
Set-Content -Path $gradleFilePath -Value $gradleContent


cd ..\android
Write-Host "Building APK..."
.\gradlew.bat assembleRelease | Out-Null
Write-Host "Building Bundle..."
.\gradlew.bat bundleRelease | Out-Null


cd $PSScriptRoot


Write-Host "Copying APK..."
if (-Not (Test-Path -Path $androidApkOutputPath)) {		
	New-Item -Path ".\" -Name $androidApkOutputPath -ItemType "directory" | Out-Null
}
$fullApkPath = "$androidApkOutputPath\$namespace-v$versionLine.apk"
Copy-Item $apkSourcePath -Destination $fullApkPath


Write-Host "Copying Bundle..."
if (-Not (Test-Path -Path $androidBundleOutputPath)) {		
	New-Item -Path ".\" -Name $androidBundleOutputPath -ItemType "directory" | Out-Null
}
$fullBundlePath = "$androidBundleOutputPath\$namespace-v$versionLine.aab"
Copy-Item $bundleSourcePath -Destination $fullBundlePath

C:\Windows\explorer.exe "/select,`"$fullApkPath"`"
C:\Windows\explorer.exe "/select,`"$fullBundlePath"`"