$deploySubDir = "kpix"
cd ..
flutter build web --base-href "/$deploySubDir/"
cd $PSScriptRoot