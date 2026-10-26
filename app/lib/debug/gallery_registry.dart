import 'entries/core_entries.dart';
import 'gallery_entry.dart';

/// Each feature adds its `entries/<feature>_entries.dart` list here.
List<GalleryEntry> galleryEntries() => [
      ...coreEntries(),
    ];
