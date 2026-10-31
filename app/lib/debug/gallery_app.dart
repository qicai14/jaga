import 'package:flutter/material.dart';

import '../core/l10n/gen/app_localizations.dart';
import '../core/theme/jaga_theme.dart';
import 'gallery_entry.dart';

const _locales = [Locale('ms'), Locale('en'), Locale('zh')];
const _scales = [1.0, 1.5, 2.0];

/// Debug-only catalogue of screen states. Chrome is English on purpose (not user-facing).
class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key, required this.entries});

  final List<GalleryEntry> entries;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Jaga gallery',
        debugShowCheckedModeBanner: false,
        theme: buildJagaTheme(const Locale('en')),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GalleryHome(entries: entries),
      );
}

class GalleryHome extends StatefulWidget {
  const GalleryHome({super.key, required this.entries});

  final List<GalleryEntry> entries;

  @override
  State<GalleryHome> createState() => _GalleryHomeState();
}

class _GalleryHomeState extends State<GalleryHome> {
  Locale _locale = _locales.first;
  double _scale = 1.0;
  GalleryEntry? _selected;

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return PopScope(
      canPop: selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selected = null);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(selected == null ? 'Gallery' : '${selected.feature}: ${selected.state}'),
          actions: [
            DropdownButton<Locale>(
              value: _locale,
              onChanged: (v) => setState(() => _locale = v!),
              items: [
                for (final l in _locales)
                  DropdownMenuItem(value: l, child: Text(l.languageCode)),
              ],
            ),
            const SizedBox(width: 8),
            DropdownButton<double>(
              value: _scale,
              onChanged: (v) => setState(() => _scale = v!),
              items: [
                for (final s in _scales) DropdownMenuItem(value: s, child: Text('x$s')),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: selected == null ? _list() : _entry(selected),
      ),
    );
  }

  Widget _list() {
    final features = <String, List<GalleryEntry>>{};
    for (final e in widget.entries) {
      features.putIfAbsent(e.feature, () => []).add(e);
    }
    return ListView(
      children: [
        for (final f in features.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(f.key, style: Theme.of(context).textTheme.titleLarge),
          ),
          for (final e in f.value)
            ListTile(title: Text(e.state), onTap: () => setState(() => _selected = e)),
        ],
      ],
    );
  }

  Widget _entry(GalleryEntry entry) {
    return Theme(
      data: buildJagaTheme(_locale),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_scale)),
        child: Localizations.override(
          context: context,
          locale: _locale,
          child: Builder(builder: entry.build),
        ),
      ),
    );
  }
}
