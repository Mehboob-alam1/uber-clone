# Uber Clone — Flutter Ride-Sharing App (User + Driver + Admin)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20RTDB%20%7C%20Storage-FFCA28?logo=firebase)](https://firebase.google.com)
[![Google Maps](https://img.shields.io/badge/Google%20Maps-Platform-4285F4?logo=googlemaps)](https://developers.google.com/maps)
[![License](https://img.shields.io/badge/License-Educational%20%2F%20Demo-lightgrey)](#license--credits)

A complete **Uber / inDriver-style ride-sharing platform** built with **Flutter** and **Firebase**.  
Includes three apps in one monorepo: **Rider (Users)**, **Driver**, and **Admin Panel**.

> Perfect for learning real-time location apps, Firebase architecture, Google Maps, GeoFire, and ride-booking flows.

---

## Credits & Attribution

**Original creator:** [Muhammad Fahad](https://github.com/offfahad) ([@offfahad](https://github.com/offfahad))  
**Original repository:** [offfahad/uber-clone](https://github.com/offfahad/uber-clone)

This project is based on Fahad’s open Uber-clone codebase.  
Maintained / customized for delivery demos by **Appo Matrix**.

Please star the [original repo](https://github.com/offfahad/uber-clone) if this helps you.

---

## Apps Included

| App | Folder | Purpose |
|-----|--------|---------|
| **Users / Riders** | `uber_users_app` | Book rides, bid fare, track driver, pay |
| **Drivers** | `uber_drivers_app` | Go online, accept trips, navigate, earn |
| **Admin Panel** | `uber_admin_panel` | Manage users/drivers/trips, verify drivers |

---

## Features

### User App
- Phone / Firebase auth + Google Sign-In
- Real-time map with current location
- Destination search via **Places API (New)**
- Route preview via **Routes API (New)**
- Vehicle types: Car / Bike / Rickshaw
- Custom **bid amount** for rides
- Nearby driver discovery with **GeoFire**
- Live trip status: accepted → arrived → on trip → ended
- Stripe payment dialog (configurable keys)
- Trip history & profile

### Driver App
- Go online / offline with live GeoFire location
- Incoming trip requests (Realtime Database + FCM)
- Accept / decline rides
- Trip flow: Arrived → Start Trip → End Trip
- Earnings tracking
- Driver document registration & profile updates

### Admin Panel
- Users & drivers management
- Trip monitoring
- Driver document verification / block status
- Flutter admin scaffold (run on **Chrome/web** or Android)

---

## Tech Stack

- **Flutter / Dart**
- **Firebase:** Auth, Realtime Database, Cloud Messaging, Storage
- **Google Maps Platform:** Maps SDK, Places API (New), Routes API (New)
- **GeoFire** for nearby driver queries
- **Provider** state management
- **Flutter Stripe** payments
- **Geolocator**, Polyline points, permissions, connectivity

---

## Project Structure

```text
uber-clone/
├── uber_users_app/          # Rider mobile app
├── uber_drivers_app/        # Driver mobile app
├── uber_admin_panel/        # Admin (web/Android)
├── packages/
│   └── flutter_geofire_patched/   # Local GeoFire fix for modern Flutter
└── README.md
```

---

## Getting Started

### Prerequisites
- Flutter SDK (stable)
- Android Studio / Xcode
- Firebase project
- Google Cloud project with Maps / Places / Routes APIs enabled
- Java 17+ (Android builds tested with Java 21 + Gradle 8.14+)

### 1) Clone
```bash
git clone https://github.com/Mehboob-alam1/uber-clone.git
cd uber-clone
```

### 2) Firebase
1. Create a Firebase project
2. Add Android apps for users, drivers, and admin (correct package names)
3. Download each `google-services.json` into:
   - `uber_users_app/android/app/`
   - `uber_drivers_app/android/app/`
   - `uber_admin_panel/android/app/`
4. Enable **Authentication**, **Realtime Database**, **Storage**, **Cloud Messaging**
5. Set Realtime Database rules appropriately for development

### 3) Google Maps API key
Put your key in:
- `uber_users_app/android/app/src/main/AndroidManifest.xml`
- `uber_drivers_app/android/app/src/main/AndroidManifest.xml`
- Dart globals (`googleMapKey` in each app)

Enable on the same key:
- Maps SDK for Android
- Places API (New)
- Routes API

### 4) Run
```bash
# Users
cd uber_users_app && flutter pub get && flutter run

# Drivers
cd ../uber_drivers_app && flutter pub get && flutter run

# Admin (recommended on web)
cd ../uber_admin_panel && flutter pub get && flutter run -d chrome
```

### 5) Release APK (users example)
```bash
cd uber_users_app
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

---

## How the Ride Flow Works

1. Driver taps **GO ONLINE NOW** → location published under `onlineDrivers`
2. User selects destination → sees fare → **Find Driver**
3. User app assigns trip ID to driver’s `newTripStatus`
4. Driver accepts → trip page opens
5. Status updates: `accepted` → `arrived` → `ontrip` → `ended`
6. User pays (Stripe dialog) / trip saved in history

> Tip for testing on **one phone**: go online in driver app first, keep it in background, then request from user app.

---

## Screenshots

Add your screenshots here for better GitHub discovery:

```text
docs/screenshots/user-home.png
docs/screenshots/driver-online.png
docs/screenshots/admin-dashboard.png
```

---

## Keywords (SEO)

`uber clone` · `flutter uber clone` · `indriver clone` · `ride sharing app flutter` ·  
`firebase realtime database taxi app` · `google maps flutter` · `geofire flutter` ·  
`flutter driver app` · `flutter admin panel` · `stripe flutter rides` · `taxi booking app`

---

## Contributing

Contributions are welcome:
1. Fork the repo
2. Create a feature branch
3. Open a PR with a clear description

Ideas: in-app chat, better state management, multi-language, analytics dashboard.

---

## License & Credits

Educational / demo use. Respect Firebase, Google Maps, and Stripe terms of service.

**Original author:** Muhammad Fahad — [github.com/offfahad](https://github.com/offfahad) — [offfahad/uber-clone](https://github.com/offfahad/uber-clone)  
**Maintained by:** Appo Matrix

If you use this project commercially, credit the original author and verify all API keys, billing, and legal requirements for your region.

---

### Star this repo if it helped you
It helps more developers find a solid Flutter ride-sharing starter.
