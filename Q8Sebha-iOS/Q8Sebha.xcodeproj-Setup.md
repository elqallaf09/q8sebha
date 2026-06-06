# Q8Sebha iOS — إعداد مشروع Xcode

## 1. إنشاء المشروع في Xcode
1. افتح Xcode → New Project
2. اختر **iOS → App**
3. المعلومات:
   - Product Name: `Q8Sebha`
   - Bundle ID: `com.q8sebha.app`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum iOS: **16.0**

## 2. إضافة الملفات
انسخ هذه المجلدات داخل مجلد المشروع:
```
Models/
ViewModels/
Views/
Services/
Utils/
Resources/
Q8SebhaApp.swift
```

## 3. الألوان في Assets.xcassets
أضف Color Set بالاسم `Primary`:
- Any: #1A7F4B
- Dark: #25A063

أضف Color Set بالاسم `Accent`:
- Any: #D4AF37

## 4. الخط (Tajawal)
- حمّل Tajawal من Google Fonts
- اسحب ملفات `.ttf` إلى المشروع
- في `Info.plist` أضف:
  ```xml
  <key>UIAppFonts</key>
  <array>
    <string>Tajawal-Regular.ttf</string>
    <string>Tajawal-Medium.ttf</string>
    <string>Tajawal-Bold.ttf</string>
  </array>
  ```

## 5. Info.plist — الأذونات
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>لرفع صور المسابيح</string>
<key>NSCameraUsageDescription</key>
<string>لتصوير المسابيح</string>
```

## 6. تشغيل الـ Backend أولاً
```bash
cd Q8Sebha-Backend
npm install
node server.js
```
التطبيق سيتصل بـ `http://localhost:3000/api`

## 7. تغيير رابط API للجهاز الحقيقي
في `Services/APIService.swift` غيّر:
```swift
let baseURL = "http://YOUR_MAC_IP:3000/api"
```

## هيكل الملفات الكامل
```
Q8Sebha-iOS/
├── Q8SebhaApp.swift
├── Models/
│   └── Models.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── AuctionViewModel.swift
│   ├── ProductViewModel.swift
│   └── CartViewModel.swift
├── Services/
│   ├── APIService.swift
│   └── WebSocketService.swift
├── Views/
│   ├── Auth/
│   │   └── LoginView.swift         (+ SignupView + SplashView + Components)
│   ├── Home/
│   │   └── MainTabView.swift
│   ├── Products/
│   │   ├── ProductsHomeView.swift
│   │   └── ProductDetailView.swift
│   ├── Auction/
│   │   ├── AuctionListView.swift
│   │   ├── AuctionDetailView.swift
│   │   └── CreateAuctionView.swift
│   └── Profile/
│       └── ProfileView.swift       (+ NotificationsView + EditProfileView)
└── Resources/
    └── Assets.xcassets/
```
