@echo off
cd /d "D:\qadamgrade"
flutter clean
flutter pub get
flutter build apk --release
pause