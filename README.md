<<<<<<< HEAD
# 🚀 nxt_gen_cart – IoT Smart Shopping System

A smart, real-time shopping solution powered by **IoT + Flutter** that eliminates checkout queues by bringing billing directly into the cart.

---

## ⚡ Overview

**nxt_gen_cart** is designed to modernize the retail experience by converting a traditional shopping cart into an intelligent system. It automatically detects products using RFID/NFC technology and updates the total bill in real-time through a connected mobile application.

This removes the need for manual scanning at billing counters and creates a seamless, queue-free shopping experience.

---

## 🧠 How It Works

1. A product is placed inside the trolley  
2. The RFID/NFC tag on the product is detected automatically  
# NxT Gen Cart

A smart, real-time shopping solution powered by IoT + Flutter that eliminates checkout queues by bringing billing directly into the cart.

## Overview

NxT Gen Cart modernizes the retail experience by converting a traditional shopping cart into an intelligent system. It detects products using RFID/NFC technology and updates the total bill in real-time through a connected mobile application.

## How It Works

1. A product is placed inside the trolley.
2. The RFID/NFC tag on the product is detected automatically.
3. The ESP32 processes the product information.
4. Data is sent to the cloud in real-time.
5. The mobile app fetches and displays updated cart details and total bill.

## Tech Stack

- Frontend: Flutter (Dart)
- Hardware: ESP32, RFID/NFC module
- Backend: Firebase Realtime Database, Firebase Hosting, Firebase Functions
- Tools: Arduino IDE, VS Code / Android Studio

## Stripe Setup

Stripe is configured via Firebase Functions so secret keys remain server-side.

1. Install dependencies:

```bash
flutter pub get
cd functions
npm install
cd ..
```

2. Set function secrets:

```bash
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
```

3. Create a Stripe webhook endpoint in Stripe Dashboard:

- URL: `https://us-central1-nxtgen-cart.cloudfunctions.net/handleStripeWebhook`
- Events: `checkout.session.completed`

## Deploy Backend + Web

```bash
firebase deploy --only functions
flutter build web --release
firebase deploy --only hosting
```

Web URL:
`https://nxtgen-cart.web.app`

## Android Build

```bash
flutter build apk --release
```

APK path:
`build/app/outputs/flutter-apk/app-release.apk`

