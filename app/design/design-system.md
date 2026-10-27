# Design system (Lane B)

Built from `ui-plan.md` (settled). Applies to every Lane B feature. Portrait Android phone, 360–412dp wide, light theme
only, Material 3. Terms follow `GLOSSARY.md`.

## 1. Point of view
**Calm every day, loud once.** Every screen except the Warning is quiet: warm paper background, deep teal ink, left-aligned
text, flat tonal surfaces, no shadows, no decoration. The one loud thing in the app is the **Warning**, designed like a road
sign: a solid red field, the command in very heavy type, the official number in pale sign-yellow. Nothing else in the app
uses red fields or yellow type, so she learns that this look means one thing.
- Left-align all text (Chinese reads better left-aligned too). The only centred element is the link code.
- One primary action per screen, full width, in the thumb zone at the bottom.
- Structure only where it carries meaning: the 6-step stage bar is a real sequence; onboarding steps are numbered because
  they are a sequence. No eyebrow labels, no all-caps, no `→` on buttons.

## 2. Colour tokens
`ColorScheme` is built by hand (`ColorScheme(brightness: Brightness.light, ...)`), not `fromSeed`, so every pair is known.
Contrast is WCAG 2.x, text on its background. AAA (7:1) for all text; outlines meet 3:1 (non-text).

| Role | Hex | On it | Hex | Ratio |
|---|---|---|---|---|
| `surface` (paper) | `#FBF8F2` | `onSurface` | `#1B1F1E` | 15.7 |
| | | `onSurfaceVariant` | `#3B4441` | 9.5 |
| `surfaceContainer` | `#EEE9DF` | `onSurfaceVariant` | `#3B4441` | 8.3 |
| `surfaceContainerHigh` | `#E7E2D7` | `onSurface` / `onSurfaceVariant` | | 12.9 / 7.8 |
| `primary` (guarded teal) | `#0B5D4F` | `onPrimary` | `#FFFFFF` | 7.8 |
| `primary` as text on `surface` | | | | 7.4 |
| `primaryContainer` | `#D5ECE4` | `onPrimaryContainer` | `#04372F` | 10.6 |
| `secondary` (slate) | `#2E4A45` | `onSecondary` | `#FFFFFF` | 9.6 |
| `tertiary` (= genuine blue) | `#1D4E89` | `onTertiary` | `#FFFFFF` | 8.4 |
| `error` | `#8C1D18` | `onError` | `#FFFFFF` | 9.1 |
| `errorContainer` | `#FCE4E1` | `onErrorContainer` | `#410E0B` | 13.4 |
| `outline` | `#6B7472` | (non-text, on `surface`) | | 4.5 |
| `outlineVariant` | `#C9C4B8` | dividers only | | |

**`JagaColors` (ThemeExtension), semantic roles:**

| Token | Hex | Text on it | Hex | Ratio |
|---|---|---|---|---|
| `guarded` / `onGuarded` | `#0B5D4F` | | `#FFFFFF` | 7.8 |
| `guardedContainer` / `onGuardedContainer` | `#D5ECE4` | | `#04372F` | 10.6 |
| `caution` / `onCaution` (amber banner) | `#FFC94A` | | `#2B1D00` | 10.7 |
| `cautionEdge` (banner bottom rule, 3dp) | `#5C1A00` | non-text | | 8.6 |
| `warning` / `onWarning` (Warning field) | `#9A0D14` | | `#FFFFFF` | 8.6 |
| `warningNumber` (official number on red) | `#FFE9A8` | on `warning` | | 7.2 |
| `genuineContainer` / `onGenuineContainer` | `#DCE8F5` | | `#0A2E52` | 11.1 |
| `genuine` / `onGenuine` (blue button) | `#1D4E89` | | `#FFFFFF` | 8.4 |
| `muted` (reconnecting dot on light) | `#6B7472` | non-text | | 4.5 |

On the Warning, the reconnecting dot is `onWarning` at 60% opacity. Never put `warning` red anywhere except the Warning
screen and the hang-up control; form errors use `error`, which is darker and browner.

## 3. Type
Fonts are bundled (no `google_fonts`, no network): family `NotoSans`, `fontFamilyFallback: ['NotoSansSC']`.
Fallback is per glyph, so mixed lines (Malay command + Chinese name) render without a per-locale theme. Sizes are sp before `TextScaler`.

| Style | Where | sp | Weight | Height |
|---|---|---|---|---|
| `JagaTextStyles.command` | Warning command (shrinks to floor 32) | 52 | 800 | 1.08 |
| `JagaTextStyles.commandEnglish` | English line under the command | 30 | 700 | 1.15 |
| `JagaTextStyles.officialNumber` | number on Warning / after call | 40 | 800, tabular figures, +1.0 letter spacing | 1.1 |
| `JagaTextStyles.linkCode` | 6-digit link code | 48 | 800, tabular, +6 letter spacing | 1.0 |
| `displaySmall` | status hero ("Jaga is protecting you") | 36 | 700 | 1.15 |
| `headlineMedium` | screen titles | 28 | 700 | 1.2 |
| `titleLarge` | card and section titles | 24 | 600 | 1.25 |
| `bodyLarge` | main text, counter-move | 22 | 400 | 1.4 |
| `bodyMedium` | secondary text (the minimum anywhere) | 20 | 400 | 1.4 |
| `labelLarge` | buttons | 22 | 600 | 1.2 |
| `labelMedium` | badges, stage labels | 20 | 600 | 1.2 |

No style is below 20sp. Unused M3 slots (`bodySmall`, `labelSmall`, `titleSmall`) are mapped to `bodyMedium`/`labelMedium`
so a stray default can't go smaller.

**Font files** (`app/assets/fonts/`, OFL 1.1, `OFL.txt` registered with `LicenseRegistry`): static instances only (variable
fonts don't follow `fontWeight` reliably): `NotoSans-{Regular,SemiBold,ExtraBold}.ttf`, `NotoSansSC-{Regular,ExtraBold}.ttf`. Weights 600/700 map to SemiBold/ExtraBold for SC.
**Subsetting** with `pyftsubset` (`uvx --from fonttools pyftsubset`, script at `app/tool/subset_fonts.py`, committed with
its output): Latin = Basic Latin, Latin-1, Latin Extended-A, General Punctuation; SC = the 3,500 first-level characters of
the Table of General Standard Chinese Characters plus every Han glyph found in the ARB files (family summaries are free text,
so don't subset to the ARB alone). Keep `--layout-features='*'`. Budget: under 5 MB total.

## 4. Spacing, radii, elevation, targets (`JagaMetrics` ThemeExtension)
- **Spacing** (4dp grid): `xs 4`, `s 8`, `m 16`, `l 24`, `xl 32`, `xxl 48`. Screen side padding `l 24` (at 360dp that leaves
  312dp for text, about 26 characters at 22sp: short lines on purpose).
- **Radii:** `small 12` (chips, inputs), `medium 20` (buttons, the Caution banner's lower corners), `large 28` (cards,
  sheets), `pill` (badges, stage-bar ends). The Warning has **no radius**: it is the full screen.
- **Elevation:** flat. Surfaces separate by tone (`surface` → `surfaceContainer` → `surfaceContainerHigh`), never by shadow.
  `CardTheme(elevation: 0)`, `AppBarTheme(scrolledUnderElevation: 0)`. Only dialogs keep M3 level 3.
- **Targets:** `minTarget 56`, `primaryButtonHeight 64`. `materialTapTargetSize: padded`, `visualDensity: standard`.

## 5. ThemeData shape (`lib/core/theme/`)
```
jaga_theme.dart     ThemeData buildJagaTheme(Locale locale)
  useMaterial3: true, colorScheme: jagaColorScheme, textTheme: jagaTextTheme(locale),
  fontFamily: 'NotoSans', scaffoldBackgroundColor: surface,
  filledButtonTheme: minimumSize Size.fromHeight(64), shape radius 20, textStyle labelLarge
  outlinedButtonTheme / textButtonTheme: minimumSize (56, 56), side 2dp outline
  inputDecorationTheme: filled surfaceContainer, radius 12, 2dp focus border primary, contentPadding 20
  extensions: [JagaColors.light, JagaMetrics.standard, JagaTextStyles.of(locale)]
jaga_colors.dart    class JagaColors extends ThemeExtension<JagaColors> (fields from §2, copyWith, lerp)
jaga_metrics.dart   class JagaMetrics extends ThemeExtension<JagaMetrics> (spacing, radii, targets)
jaga_text_styles.dart class JagaTextStyles extends ThemeExtension<JagaTextStyles> (command, commandEnglish,
                    officialNumber, linkCode)
theme_context.dart  extension on BuildContext: context.jagaColors, context.metrics, context.jagaText
```
`MaterialApp` passes `theme: buildJagaTheme(locale)` only (no `darkTheme`, `themeMode: ThemeMode.light`).

## 6. Platform behaviour (all screens)
- **Edge-to-edge:** `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` in `main`; each screen wraps content in
  `SafeArea`. Light screens use `SystemUiOverlayStyle.dark` icons; the Warning sets `.light` via `AnnotatedRegion`.
- **Portrait only:** `SystemChrome.setPreferredOrientations([portraitUp])` and `android:screenOrientation="portrait"`.
- **Text scale:** read `MediaQuery.textScalerOf(context)`; never fixed heights around text; `ConstrainedBox(minHeight)` only.
  Long content scrolls (`SingleChildScrollView`) except the Warning command region (see `warning.md`). Must work at 2.0.
- **Motion:** at most one orchestrated moment per screen. Check `MediaQuery.disableAnimationsOf(context)`; when true,
  durations become `Duration.zero`. Standard duration 200 ms, `Curves.easeOutCubic`. No looping animations on calm screens.
- **Back:** predictive back on (`android:enableOnBackInvokedCallback="true"`). Screens that must not close use
  `PopScope(canPop: false)`.
- **TalkBack:** every icon-only control has a `Semantics` label; status changes use `Semantics(liveRegion: true)`.

## 7. Shared widgets (`lib/core/widgets/`)
| Widget | Purpose | API sketch |
|---|---|---|
| `BigButton` | the one primary action | `BigButton({required String label, IconData? icon, required VoidCallback? onPressed, BigButtonTone tone = guarded})`; tones `guarded`, `genuine`, `onWarning` (white fill, red text), `quiet` (outlined). Height 64, full width, label wraps (no ellipsis) |
| `HoldToConfirmButton` | dismiss a Caution/Warning, clear Jaga Pause | `({required String label, String? secondLabel, Duration hold = 2s, required VoidCallback onConfirmed, HoldTone tone, double height = 64})`. Fill sweeps left→right while held; release early rewinds (200 ms, instant if animations off). Haptics: `selectionClick` on press, `heavyImpact` on confirm. With `MediaQuery.accessibleNavigationOf` true: first activation arms it and announces the confirm hint, a second activation within 5 s confirms. Semantics: button, label, hint |
| `ShrinkToFitText` | text that must fit a box without scrolling | `({required String text, required TextStyle style, double minFontSize = 32, int? maxLines})`. In a `LayoutBuilder`, measures with `TextPainter` (using the ambient `TextScaler`) and steps the size down 2sp at a time until it fits; never below `minFontSize`; at the floor it clips nothing and reports overflow to the parent via `onOverflow` |
| `StageProgressBar` | family alert and timeline | `({required Stage stage, bool compact = false})`. 6 segments `pretext`…`money`/`credentials` (`money` and `credentials` tie as most severe and share segment 6, labelled by whichever is reached); filled up to the stage; plain-word label under it; Semantics "Step 6 of 6: Asked to move money" |
| `StatusBadge` | "Jaga Pause active", "protected" | `({required String label, BadgeTone tone, IconData? icon})`, pill, `labelMedium`, min height 40 (not tappable) |
| `ReconnectingDot` | stream dropped | `({required bool visible, Color? color})`; 12dp dot, 48dp hit area, Semantics label `callReconnecting`, no animation |
| `ScreenFrame` | page scaffold | `({String? title, required Widget body, Widget? bottomAction})`: `Scaffold` + `SafeArea` + side padding 24 + bottom action pinned above the gesture bar |

Feature-specific widgets stay in `lib/features/<feature>/views/widgets/`.

## 8. Haptics (`lib/core/haptics/`)
`abstract class Buzzer { Future<void> startWarningPattern(); Future<void> stop(); Future<void> playOnce(); }` with
`VibrationBuzzer` (real) and `FakeBuzzer` (records calls, for tests and the gallery). The pattern itself is defined in
`warning.md` §6 and reused by onboarding's "Feel the buzz". Button feedback uses Flutter's `HapticFeedback` directly.

## 9. Localisation (`lib/core/l10n/`)
- `flutter_localizations` (SDK) + `intl`, `fvm flutter gen-l10n` with `l10n.yaml`: `arb-dir: lib/core/l10n/arb`,
  `template-arb-file: app_en.arb`, `output-dir: lib/core/l10n/gen`, `output-class: AppLocalizations`, `nullable-getter: false`.
- Files: `app_en.arb` (template, written by the architect), `app_ms.arb`, `app_zh.arb` (Simplified; filled by
  flutter-dev, flagged for native review). `supportedLocales: [ms, en, zh]`; fallback locale `ms`.
- **Key naming:** `<feature><Element><Variant?>` in lowerCamelCase, e.g. `warningDismissLabel`, `cautionBannerText`,
  `familyAlertCallButton`. Shared words use `common…`. Every key has an `@key` description saying where it appears.
  Placeholders are named (`{agency}`, `{name}`), never positional.
- **Bilingual pairs** (command language then English, as on the Warning): look up the English with
  `lookupAppLocalizations(const Locale('en'))` and show it only when it differs from the first line.
- The protected phone's locale is the stored command language (default `ms`), not the system locale. Phrase-library text
  (command, counter-move) never goes in the ARB files: it comes through the contract (ADR 0006).

## 10. Debug gallery (`lib/debug/`, debug builds only)
- Separate entry point `lib/main_gallery.dart` (`fvm flutter run -t lib/main_gallery.dart`). `main.dart` never imports
  `lib/debug/`, so release builds can't contain it.
- `GalleryEntry({required String feature, required String state, required Widget Function(BuildContext) build})`. Each
  feature adds `lib/debug/entries/<feature>_entries.dart` returning `List<GalleryEntry>`; `gallery_registry.dart` concatenates them.
- The gallery home lists entries grouped by feature. A top bar switches locale (ms/en/zh) and text scale (1.0/1.5/2.0)
  by wrapping the entry in `Localizations.override` and `MediaQuery(textScaler: ...)`.
- **Fixtures** live in `lib/debug/fixtures/` as raw JSON strings (`const stageUpdateHigh = r'''{...}''';`) and are parsed
  through the real `fromJson`, so the gallery and widget tests exercise the model layer. A test
  (`test/contracts/fixtures_match_schema_test.dart`) validates every fixture string against `../contracts/*.schema.json`.

## 11. Dependency proposals (own PR, per `docs/delivery.md`)
- `flutter_localizations` (SDK), `intl`: l10n.
- `vibration`: patterned vibration with amplitude (Flutter's `HapticFeedback` can't play a pattern). Needs `VIBRATE` permission.
- `proximity_sensor` (or equivalent): to stop the Warning buzz when the phone leaves her ear (`warning.md` §6).
- dev: `json_schema`: the fixture contract check.
