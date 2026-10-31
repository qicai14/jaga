import 'entries/call_entries.dart';
import 'entries/core_entries.dart';
import 'entries/family_entries.dart';
import 'entries/live_call_entries.dart';
import 'entries/onboarding_entries.dart';
import 'entries/warning_entries.dart';
import 'gallery_entry.dart';

/// Each feature adds its `entries/<feature>_entries.dart` list here.
List<GalleryEntry> galleryEntries() => [
  ...callEntries(),
  ...coreEntries(),
  ...familyEntries(),
  ...liveCallEntries(),
  ...onboardingEntries(),
  ...warningEntries(),
];
