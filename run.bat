cd C:\p2p\p2p_tutoring_application
@echo off
echo Cleaning Flutter project...
call flutter clean
call flutter pub cache clean
cd android
call gradlew --stop
cd ..
rmdir /s /q build 2>nul
rmdir /s /q .dart_tool 2>nul
rmdir /s /q android\.gradle 2>nul
rmdir /s /q android\app\build 2>nul
del android\local.properties 2>nul
echo Getting dependencies...
call flutter pub get
echo Done! Now run: flutter run