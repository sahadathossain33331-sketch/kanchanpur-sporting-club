# কাঞ্চনপুর স্পোর্টিং ক্লাব — Android + iPhone Final Project

এই Flutter project একই codebase থেকে Android ও iPhone app বানানোর জন্য প্রস্তুত।

## App structure

Home screen:
1. নতুন সদস্যের জন্য আবেদন
2. মাসিক চাঁদা / ডোনেশন
3. Admin Panel

### আবেদন ফর্ম
- নাম
- ছবি আপলোড
- পিতার নাম
- মাতার নাম
- জন্মসাল
- NID/জন্মনিবন্ধন
- জেলা
- থানা
- গ্রাম
- রক্তের গ্রুপ
- মোবাইল
- Submit

**আবেদন ফর্মে কোনো Payment field নেই।**

### আলাদা Payment section
- বিকাশ — 01897173332 (Personal)
- নগদ — 01897173332 (Personal)
- রকেট — 01897173332
- টাকার পরিমাণ
- Transaction ID
- Payment Submit

## Android APK বানানো

কম্পিউটারে Flutter SDK ও Android Studio ইনস্টল করে project folder-এ:

```bash
flutter pub get
flutter build apk --release
```

APK পাওয়া যাবে:

`build/app/outputs/flutter-apk/app-release.apk`

Play Store-এর জন্য:

```bash
flutter build appbundle --release
```

## iPhone app বানানো

iPhone build-এর জন্য macOS এবং Xcode প্রয়োজন।

```bash
flutter pub get
flutter build ios --release
```

App Store/TestFlight-এর জন্য Xcode দিয়ে signing, Team এবং Bundle Identifier সেট করতে হবে।

## গুরুত্বপূর্ণ

এই project-এ real Firebase credentials এবং real payment gateway credentials এখনো বসানো নেই।
Personal bKash/Nagad/Rocket payment-এর ক্ষেত্রে Transaction ID নেওয়া হয় এবং Admin manually verify করতে পারে।
