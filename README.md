# Kanchanpur Sporting Club — V5 (Supabase-ready)

Firebase বাদ দিয়ে Supabase backend-এর জন্য project প্রস্তুত করা হয়েছে।

## কেন Supabase
শুরুতে free-tier দিয়ে development করা যায়; database, authentication এবং storage একই dashboard থেকে পরিচালনা করা যায়। Free-tier limits/provider policy অনুযায়ী পরিবর্তিত হতে পারে।

## Setup
1. Supabase dashboard-এ নতুন project তৈরি করুন।
2. SQL Editor-এ `supabase/schema.sql` চালান।
3. Authentication থেকে Email/Password বা প্রয়োজনীয় login method চালু করুন।
4. Storage-এ `member-photos` bucket তৈরি করুন এবং secure policies দিন।
5. Project URL এবং anon/publishable key `lib/main.dart`-এ বসান।
6. `Supabase.initialize` uncomment করুন।
7. `flutter pub get`
8. `flutter build apk --release`

## Payment
Payment আবেদন ফর্মের সঙ্গে যুক্ত নয়। আলাদা Payment page আছে:
- bKash: 01897173332 (Personal)
- Nagad: 01897173332 (Personal)
- Rocket: 01897173332

Personal payment হলে Transaction ID দিয়ে Admin manual verification করবে।

## নিরাপত্তা
- `service_role` key কখনো Flutter app-এ রাখবেন না।
- Admin operations-এর জন্য server-side/admin role policy ব্যবহার করুন।
- ব্যক্তিগত NID তথ্যের access কঠোরভাবে সীমাবদ্ধ রাখুন।
