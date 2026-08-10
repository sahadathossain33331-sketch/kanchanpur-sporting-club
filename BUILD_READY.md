# Build-ready project

This project now contains Android application/build structure and a Codemagic workflow.

Android:
1. Push this project to GitHub.
2. Connect the repository to Codemagic.
3. Start the `android-release` workflow.
4. Download `app-release.apk` from the build artifacts.

Important:
- The app contains a Supabase project URL and publishable key only.
- Never add a service_role/secret key to the Flutter app.
- The bKash/Nagad/Rocket numbers are personal/manual-payment numbers; transaction IDs require admin verification.
- iOS still requires Apple signing/team configuration before App Store/TestFlight distribution.
