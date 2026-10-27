# app/ (Flutter, Android first, plus a web target for the Demo Bank)

- Always `fvm flutter ...`, never a global `flutter`. Version lives in `.fvmrc` and `pubspec.yaml`.
- Code by feature: `lib/features/<feature>/` (call, warning, family, onboarding, demo_bank). Shared code in `lib/core/`.
- Server messages are typed from `contracts/*.schema.json`. Don't invent fields; ask for a contract change.
- Warnings follow the plan: one big **command** first, the explanation after. Large text, high contrast, in the user's language
  (Malay, English, Mandarin via `flutter-setup-localization`).
- Every screen gets a widget test. Run `fvm flutter analyze` and `fvm flutter test` before every PR.
- iOS is out of scope (ADR 0001). Don't add iOS-only packages or code.
