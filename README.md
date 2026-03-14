# SChat — Self-hosted Messenger

A complete, beautiful messenger app built with Flutter + Matrix backend.

## Features
- 💬 Text, Voice, Image, Video, GIF, PDF, File sharing
- 📞 Audio & Video calls (WebRTC)
- 🔒 End-to-end encryption (Matrix)
- 🌐 Works on Android, iOS, Web, Desktop
- 🖥️ Self-hosted on your own server

## Server
- **Matrix Homeserver**: matrix.softvibeitgarden.tech
- **Powered by**: Synapse + Fly.io

---

## 🚀 Get APK (Easiest Way)

1. Push this code to GitHub
2. Go to **Actions** tab
3. Click **Build SChat APK**
4. Wait ~5 minutes
5. Download APK from **Artifacts**

---

## 🛠️ Local Build

### Requirements
- Flutter 3.24+
- Android Studio / VS Code
- Java 17

### Steps
```bash
# 1. Install dependencies
flutter pub get

# 2. Generate code
flutter pub run build_runner build

# 3. Build APK
flutter build apk --debug

# APK location:
# build/app/outputs/flutter-apk/app-debug.apk
```

---

## 📱 Install APK on Android

1. Enable **"Unknown Sources"** in Settings
2. Copy APK to phone
3. Tap to install

---

## 🔧 Configuration

Edit `lib/services/matrix_service.dart`:
```dart
const String kMatrixHomeserver = 'https://matrix.softvibeitgarden.tech';
```

---

## 📁 Project Structure

```
lib/
├── main.dart              # Entry point
├── theme/                 # Colors, fonts
├── router/                # Navigation
├── services/
│   ├── matrix_service.dart  # Matrix backend
│   └── call_service.dart    # WebRTC calls
└── screens/
    ├── splash_screen.dart
    ├── login_screen.dart
    ├── home_screen.dart
    ├── chat_screen.dart
    ├── audio_call_screen.dart
    ├── video_call_screen.dart
    ├── call_history_screen.dart
    └── other_screens.dart
```
