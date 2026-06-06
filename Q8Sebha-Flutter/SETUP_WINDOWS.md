# تشغيل Q8Sebha على Windows بـ Flutter

## 1. تثبيت Flutter
1. اذهب إلى: https://docs.flutter.dev/get-started/install/windows
2. حمّل Flutter SDK وافتحه في `C:\flutter`
3. أضف `C:\flutter\bin` إلى متغير PATH
4. في Terminal: `flutter doctor` — تأكد كل شيء ✅

## 2. تثبيت Android Studio
1. حمّله من: https://developer.android.com/studio
2. ثبّته وافتح Android Studio
3. اذهب إلى: Tools → SDK Manager → تثبيت Android SDK
4. اذهب إلى: Tools → AVD Manager → Create Virtual Device (اختر Pixel 7 API 34)
5. شغّل المحاكي

## 3. تشغيل المشروع
```bash
# في Terminal/PowerShell داخل مجلد Q8Sebha-Flutter
cd C:\Users\User\q8sebha\q8sebha\Q8Sebha-Flutter

# تثبيت المكتبات
flutter pub get

# تشغيل (تأكد المحاكي شغّال أولاً)
flutter run

# أو بناء APK
flutter build apk --release
```

## 4. تشغيل Backend أولاً
```bash
cd C:\Users\User\q8sebha\q8sebha\Q8Sebha-Backend
npm install
node server.js
```

## 5. الفونت Tajawal
- حمّل من: https://fonts.google.com/specimen/Tajawal
- اسحب الملفات إلى: `Q8Sebha-Flutter/assets/fonts/`
- الملفات المطلوبة:
  - Tajawal-Regular.ttf
  - Tajawal-Medium.ttf
  - Tajawal-Bold.ttf

## 6. الصور
- أنشئ مجلد: `Q8Sebha-Flutter/assets/images/`
- ضع شعار التطبيق باسم: `logo.png`

## ملاحظة: رابط API
في `lib/services/api_service.dart`:
- المحاكي (Android Emulator): `http://10.0.2.2:3000/api`  ← هذا الافتراضي
- هاتف حقيقي: `http://YOUR_PC_IP:3000/api`  ← مثل `http://192.168.1.5:3000/api`

## هيكل المشروع
```
Q8Sebha-Flutter/
├── pubspec.yaml
├── lib/
│   ├── main.dart              ← نقطة البداية + الثيم
│   ├── models/
│   │   └── models.dart        ← User, Product, Auction, Order...
│   ├── services/
│   │   ├── api_service.dart   ← HTTP + JWT
│   │   └── websocket_service.dart ← تحديثات حية
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── auction_provider.dart
│   │   ├── product_provider.dart
│   │   └── notification_provider.dart
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── auth/login_screen.dart
│   │   ├── home/main_screen.dart
│   │   ├── products/
│   │   ├── auctions/
│   │   ├── notifications/
│   │   └── profile/
│   └── widgets/
│       └── common_widgets.dart
└── assets/
    ├── fonts/
    └── images/
```
