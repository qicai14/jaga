# 0001: Android only for the hackathon

**Decision:** ship the Flutter app on Android. iOS goes on the roadmap.
**Why:** iOS incoming VoIP calls need PushKit + CallKit, a paid Apple Developer account, a Mac to build and a physical iPhone
to test. The team works on Windows. Android needs only an emulator or phone plus FCM.
**Consequence:** no iOS-only packages or code. The Demo Bank uses Flutter's web target.
