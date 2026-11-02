# Launcher icon (Lane B)

Replaces the Flutter logo. Tokens come from `app/design/design-system.md` §2. No image tools: every layer is a vector drawable.

## 1. Concept
**Point of view:** a seal you'd find on a letter from someone you trust. It's the same teal and paper as the masthead on the
Jaga notice. Flat, two colours, no gloss, no tick, no glow. The tile is a printed seal, not a security product.

| Option | Reads as | Verdict |
|---|---|---|
| A. Bare shield (paper on teal) | "protection". This is the notification glyph, scaled up. | No. It's the antivirus cliché, and a shield alone has no name. On a crowded home screen it looks like a generic VPN or cleaner app. |
| B. "J" monogram (paper on teal) | A bank or institution letterform, like the `JagaWordmark` | Close, but a lone letter says nothing about guarding. Lots of apps use a single letter, and an older user has to read it rather than recognise it. |
| **C. Shield with a J cut through it** (recommended) | "Jaga's shield". The paper shield carries the meaning and the teal J names it. | **Yes.** It is recognisable by shape at a glance and named by the letter. The J is the same teal as the tile, so it reads as a cut-out, like a stamp, not an extra colour. |

**Relation to the notification:** C uses the *exact* path from `ic_stat_jaga.xml`, scaled up. The status bar shows the bare
shield and the home screen shows the same shield signed with the J, so the two read as one family. Leave `ic_stat_jaga.xml`
unchanged: at 24dp a J cut-out is only about 2dp wide and would turn to mush. The Warning brief's "no shield on the notice"
rule still holds, because the icon is identity, not content.

## 2. Geometry and colours (option C)
Everything is drawn in the 24-unit space of the notification glyph, then placed with a group: `scaleX/Y="2.5"` and
`translateX/Y="24"` inside a 108×108 viewport (108dp). That maps (12,12) to (54,54).
- **Background layer:** a solid `guarded` `#0B5D4F` fill across the whole 108dp. No gradient and no inner tile.
- **Shield:** `paper` `#FBF8F2`, path `M12,1L3,5v6c0,5.55 3.84,10.74 9,12 5.16,-1.26 9,-6.45 9,-12V5L12,1z`. On the canvas it
  is 45×55dp, centred. Its farthest point (the top corners) is 28.5dp from the centre, so it sits well inside the 33dp
  radius that survives the circle mask (66dp) and inside the 72dp safe square.
- **J:** `#0B5D4F`, drawn as a filled outline (not a stroke) so the same path works as a hole in the monochrome layer:
  `M13.7,6H16.3V13A4.55,4.55 0 0 1 7.2,13H9.8A1.95,1.95 0 0 0 13.7,13Z`
  The stem is 2.6 units wide (6.5dp) with a flat top, like NotoSans ExtraBold. The bowl is a semicircle centred on x 11.75,
  so the J sits about 1 unit right of the shield's axis. That optically centres it, because the stem carries the weight.
  The J runs y 6 to 17.55, at least 2.3 units from every shield edge.
- **Contrast:** paper on teal is 7.4:1 (AAA). Against wallpapers, the teal tile is 7.8:1 on white but only 2.7:1 on black.
  On dark wallpapers the paper shield (about 19:1 on black) carries recognition, which is why the shield is large.
- **Themed icon (Android 13+, `<monochrome>`):** a single path with `android:fillType="evenOdd"`: the shield path followed by
  the J path. The J becomes a hole, so the system tint fills the shield and the J shows the themed background. The group
  transform is the same. Use alpha only, with fill `#FFFFFFFF`.
- **At 48dp:** the shield is about 37dp tall, the J stem about 4.3dp and the bowl's counter about 6.5dp, so all three
  survive.

## 3. Implementation plan (one small PR, `preston/<id>-launcher-icon`)
1. `res/drawable/ic_launcher_background.xml`: a vector, 108dp, one path `M0,0h108v108h-108z` filled `#0B5D4F`.
   Add `<color name="jaga_guarded">#0B5D4F</color>` to `values/colors.xml` and reference it, so the hex lives in one place
   on the Android side.
2. `res/drawable/ic_launcher_foreground.xml`: a vector, 108dp, with a `<group scale 2.5, translate 24>` containing the
   shield path (paper) and the J path (teal).
3. `res/drawable/ic_launcher_monochrome.xml`: the same group, with one evenOdd path made of the shield and the J.
4. `res/mipmap-anydpi-v26/ic_launcher.xml`:
   `<adaptive-icon><background @drawable/ic_launcher_background/><foreground @drawable/ic_launcher_foreground/><monochrome @drawable/ic_launcher_monochrome/></adaptive-icon>`
5. **No legacy icon:** `minSdk` is 29 (Android 10), so every device uses the adaptive icon. Delete the five Flutter
   `mipmap-*dpi/ic_launcher.png` files.
6. `AndroidManifest.xml`: add `android:roundIcon="@mipmap/ic_launcher"` and change `android:label="jaga"` to **`"Jaga"`**.
   It is a proper noun and matches the `JagaWordmark`. Don't localise it: "Jaga" is the brand in ms, zh and en.
7. There is no Dart change and no widget test. The splash (`launch_background.xml`) is out of scope; it could become a
   `#FBF8F2` window background later.

## 4. Acceptance checks (emulator, API 34)
- [ ] **Masks** (Settings > Wallpaper and style > app grid / icon shape, or a Pixel launcher with the shape changed):
  circle, squircle, rounded square and teardrop. The shield's corners and point are never clipped, and the gap from
  the tile edge looks even.
- [ ] **Themed:** with Themed icons on (Wallpaper and style), the icon is a tinted shield with a clean J-shaped hole. It
  never shows as a flat blob or as the full-colour icon.
- [ ] **48dp:** on the home screen at default grid and at Display size Largest, the J reads as a J, not a hook or a "U".
  Also check it in the app drawer and Recents.
- [ ] **Wallpapers:** solid white, solid black, a busy photo and a teal-ish wallpaper. The shield silhouette is
  identifiable in under a second on every one.
- [ ] **Label:** shows as "Jaga" under the icon; Settings > Apps lists "Jaga".
- [ ] **Brand:** no gradient, shadow, tick or extra colour. Put it next to a real antivirus icon: it should read as a bank
  or post office, not as security software.

## Decisions (implementation)
- Colours live in `res/values/colors.xml` (`jaga_guarded`, `jaga_paper`), shared by the icon and the splash.
- Splash: both `launch_background.xml` files and all four `windowBackground` entries (`LaunchTheme`/`NormalTheme`, day and
  night) use `jaga_paper`, so nothing flashes white or black. The app is light-only (`ThemeMode.light`).
- No centred logo on the splash: the foreground layer is a paper shield, which would vanish on a paper background.
- No legacy icon (`minSdk` 29); the five PNGs are deleted.
- `ic_stat_jaga.xml` is unchanged. Emulator acceptance checks (section 4) are still to be run.
