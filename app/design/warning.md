# Warning and Caution (#9; live stream in #19)

From `ui-plan.md` §2 and `design-system.md`. Protected user's phone only. Contract: `contracts/stage-update.schema.json`
(draft v0; #1 not landed). Phrase-library text only (ADR 0006): the app shows `command` and `counterMove` as given.

## 1. Architecture
```
lib/data/models/stage_update.dart        StageUpdate.fromJson (typed from the schema), enums Stage, Risk, Source
lib/data/services/stage_stream_service.dart  abstract StageStreamService { Stream<StageUpdate> updates;
                                             ValueListenable<bool> connected; }  + FakeStageStreamService (scripted fixtures)
lib/data/services/attention_service.dart     abstract { Stream<void> looked; }  proximity "far" for 1 s; + Fake
lib/data/repositories/call_risk_repository.dart  wraps the stream; drops updates for another callId
lib/features/warning/view_models/warning_view_model.dart  ChangeNotifier
lib/features/warning/views/warning_overlay.dart   WarningOverlay({required WarningViewModel vm, required Widget child,
                                                  required VoidCallback onHangUp})
lib/features/warning/views/widgets/  caution_banner.dart, warning_screen.dart
lib/debug/placeholder_call_screen.dart   the #9 host (§7)
```
`WarningOverlay` is a `Stack`: `child` (the call screen), then the Caution banner (top), then the Warning (fills). #12 wraps
its real call screen in it; the fallback (full-screen notification) can push `WarningScreen` alone as a route.

**View model state** (immutable snapshot `WarningState`, rebuilt with `ListenableBuilder`):
`layer` (`none` | `caution` | `warning`), `content` (`command`, `commandEnglish`, `counterMove`, `officialNumber`,
`agency`, `evidence`, `isCredentials`), `reconnecting`, plus private `dismissed`, `lastStage`, `lastRisk`.

## 2. Rules (all in the view model, unit-tested)
| Input | Result |
|---|---|
| `risk=low` | `layer=none`. Nothing is drawn, no buzz. She never sees a "safe" message |
| `risk=medium` | `layer=caution`. No command, no buzz |
| `risk=high` | `layer=warning`. Buzz starts (§6) |
| high → medium | Warning steps down to the Caution banner, buzz stops |
| medium → low | banner disappears |
| `stage=credentials` at high | credentials variant: same screen, the server's credentials command, hand icon instead of call-end icon |
| hold-to-dismiss confirmed | `dismissed=true`: layer hidden on this phone only. Stream, family alerts and Jaga Pause untouched |
| while dismissed: `stage` changes, or `risk` is higher than the previous update's | `dismissed=false`; the layer for the new risk shows (and buzzes if high) |
| while dismissed: same or lower | stays hidden |
| `command` text changes while the Warning is up | content swaps in place, buzz restarts |
| `connected=false` | freeze `layer` and `content`, show the reconnecting dot. Back to normal on reconnect. No message |
| new `callId` / call ends | reset all state, stop buzz |
| `risk=high`, `command` null | still show the Warning with `warningCommandFallback` (fail-safe safety net, Q35) |

"Higher than the previous update" (not the dismissal point) means high → medium → high re-shows the Warning.

## 3. Caution banner (medium)
```
MediaQuery.withClampedTextScaling(max 1.5) > Positioned(top) > Semantics(liveRegion, container)
 > Material(color: caution, bottom radius medium 20) + 3dp cautionEdge rule
  SafeArea(bottom: false) > Padding(l24, m16) > Column
    Row: JagaWordmark(small, onCaution) | Spacer | ReconnectingDot(onCaution, when reconnecting)
    gap s8; Text(cautionBannerText, titleLarge, onCaution)
    gap m16; DismissButton(calm, height 56)
```
Wordmark row, then the text, then dismiss. The ear icon is gone (an ear reads as "you are being listened to"). Slides down
200 ms (instant if animations off). At 2.0 the banner stays within about 40% of the height. Never buzzes.

## 4. Warning (high), "the Jaga notice"
**Point of view:** an official notice from someone she already trusts, not an alarm. Same `surface` paper and teal as the
rest of Jaga; red appears once (the command band) plus the red Hang up button. One typeface, no italics, no yellow.
Urgency comes from the buzz and the command. **Reviewer rejects:** flashing or pulsing, an all-red screen, more than one
icon (no `!`, triangle, shield, siren, ear, hand), countdowns, all-caps or `!` in copy, mixed sizes in one block,
link-styled text, two equally loud buttons.
```
AnnotatedRegion(SystemUiOverlayStyle.light) > PopScope(canPop: false)
 > Semantics(scopesRoute, namesRoute, label: warningFromJaga, explicitChildNodes)
 > FadeTransition 150 ms > Material(color: surface) > Column
  1 Masthead: ColoredBox(guarded, full bleed under the status bar) > SafeArea(bottom: false), min height 56:
      JagaWordmark(large, onGuarded) + Text(warningSemanticsLabel, titleMedium, onGuarded)  (Semantics header, texts excluded)
      ReconnectingDot(onGuarded) at the end
  2 Command band: ColoredBox(warning), full bleed, padding l24/v24
      ShrinkToFitText(command, command style, onWarning)   // max height 30% of body, floor 32sp
      gap s8; Text(commandEnglish, onWarning)               // only if it differs
  3 Expanded > Scrollbar(thumbVisibility) > SingleChildScrollView > Padding(l24, top l24) > Column   // body text capped at 1.4
      Text(counterMove, bodyLarge, onSurface)
      gap l24; Text(number label, bodyMedium, onSurfaceVariant)
      FittedBox(scaleDown) > Text(officialNumber, officialNumber style, onSurface)      // one line, never wraps
      gap m16; Text(counterMoveEnglish, bodyMedium, onSurfaceVariant)
      Divider(outlineVariant); Text(evidence label) + Text("“evidence”", bodyLarge, maxLines 3)  // not on credentials (Q36)
      gap xl; DismissButton(calm)                           // end of the scroll area, still hold-to-confirm
  4 Footer (pinned): Padding(l24, v16) > BigButton(hangUp, call_end, warningHangUp, maxTextScale 1.5)
```
- **Credentials:** same tree; no evidence, no divider, no hand icon (the masthead is the only mark).
- **Safety net** (`command` null): band shows `warningCommandFallback` alone; region 3 shows whatever arrived; if empty only
  the dismiss shows.
- **Fit rule:** at 393x852 and text 2.0 the command, counter-move and full official number are visible without scrolling
  (budget: masthead 64, band <= 240, counter-move ~200, number ~100, footer ~104). The command never scrolls; the band
  shrinks first, then region 3 scrolls. At 1.0 region 3 uses `spaceBetween` so the dismiss rests above Hang up.
- **English fallback:** a phrase missing in her language arrives as English; when equal to the command it is shown once.
- **Motion:** a single 150 ms fade, no wipe or pulse. Off when `disableAnimations`.
- **Reconnecting:** content frozen; a 12dp `onGuarded` dot in the masthead (banner: wordmark row). Never text.
- **Back:** does nothing while the Warning is up. Only the hold-to-dismiss closes it.
- **Widgets:** `JagaWordmark` (core; "Jaga", NotoSans 800, -0.5 spacing; large 28sp, small 22sp; own cap 1.3; excluded from
  semantics). `BigButton` gains tone `hangUp` (fill `warning`, label `onWarning`) and `maxTextScale`. `HoldToConfirmButton`
  gains `maxTextScale` (dismiss passes 1.5). `warningNumber` is no longer used on this screen.

## 5. Copy (`app_en.arb`; ms/zh by flutter-dev)
| Key | en | ms | zh |
|---|---|---|---|
| `warningFromJaga` | Scam warning from Jaga | Amaran penipuan daripada Jaga | 来自 Jaga 的诈骗警告 |

Route name for TalkBack ("Jaga" is never translated). The rest:
| Key | English | Notes |
|---|---|---|
| `cautionBannerText` | This call has signs of a scam | glossary wording |
| `warningSemanticsLabel` | Scam warning | the masthead's visible label |
| `warningOfficialNumberLabel` | {agency}'s official number | `agency` = `claimedAgency` |
| `warningOfficialNumberLabelNoAgency` | Official number | |
| `warningEvidenceLabel` | The caller said | |
| `warningHangUp` | Hang up | |
| `warningDismissLabel` | This call is fine | ms: "Panggilan ini selamat" |
| `warningDismissHint` | Hold for 2 seconds | semantics hint |
| `warningDismissConfirmHint` | Tap again to confirm this call is fine | TalkBack two-step |
| `warningCommandFallback` | Letak telefon. Hang up. | only if `command` is null at high; Lane D to approve (Q35) |
| `callReconnecting` | Reconnecting | semantics only, never shown as text |

## 6. Buzz and TalkBack
- **Pattern** (`vibration`, amplitude 255): `[0, 120, 80, 120, 80, 120, 80, 700]` then 1,000 ms gap = 2.3 s per cycle, three
  short then one long. Repeats until: `looked` (proximity far for 1 s), any touch on the Warning, dismiss, step-down, call
  end, or 60 s. Re-armed by the next re-show or command change. Caution: no buzz. No sound into the call.
- **TalkBack:** the Warning is a new route scope named `warningFromJaga` ("Scam warning from Jaga", heard once; the masthead texts are
  excluded), and the overlay also calls `SemanticsService.sendAnnouncement` with "command. commandEnglish". Focus order:
  masthead, command, English, counter-move, number, English counter-move, evidence, dismiss, Hang up. The official number has a
  `semanticsLabel` with spaces between digits so it is read digit by digit. The banner is a polite live region.

## 7. Placeholder call-screen host (debug only, until #12)
`PlaceholderCallScreen`: `ScreenFrame` with a caller number (`+60 3-2610 1599`, fixture), a static timer "02:14", and a
disabled round hang-up button at the bottom. Wrapped in `WarningOverlay` with `FakeStageStreamService`, `FakeBuzzer` and a
fake attention service. Gallery entries: `low`, `medium`, `high`, `high-credentials`, `high-english-only`,
`high-long-text`, `high-no-number`, `dismissed`, `stepped-down`, `reconnecting-high`, `reconnecting-medium`.

## 8. Contract fields → elements
| Element | Field | Status |
|---|---|---|
| layer choice | `risk` | in v0 |
| credentials variant, re-show rule | `stage` | in v0 |
| state reset | `callId` | in v0 |
| command (her language) | `command` | in v0 (non-null only at high) |
| counter-move | `counterMove` | in v0 |
| agency in number label | `claimedAgency` | in v0 |
| evidence line | `evidence[0]` | in v0 (masked caller quote) |
| English command / counter-move | none | **missing**: needs `commandEnglish`, `counterMoveEnglish` (or phrase IDs + local table) |
| official number as big text | none | **missing**: needs `officialNumber` from `official_contact` |
| reconnecting dot | none (connection state of the service) | not a contract field |
| `source`, `at` | not shown | |
Until #1 lands, missing fields are nullable in the model and their elements are hidden (no parsing numbers out of text).

## 9. Widget tests (`test/features/warning/`), each at 393×852 and again at text scale 2.0
1. low: nothing from the overlay in the tree; call screen unchanged.
2. medium: banner text shown, no command, `FakeBuzzer` not started.
3. high: command appears before English, counter-move, number, evidence in paint and semantics order; buzz started.
4. high, 2.0 scale and a 60-character command: command `fontSize` ≥ 32 effective, no overflow errors, no scroll in the band.
4b. high at 2.0: command, counter-move and official number are inside the viewport above the pinned Hang up; one icon only;
    masthead present with the `warningFromJaga` semantics; dismiss is in the scroll area and still hold-to-confirm.
5. high-credentials: credentials command; no evidence line even if `evidence` is non-empty; no hand icon.
6. English-only phrase: command shown once.
7. Hold 1 s and release: still shown. Hold 2 s: hidden, buzz stopped, repository received nothing (dismiss is local).
8. Dismissed, then same update: hidden. Then a new stage: Warning back and buzz restarts.
9. high → medium: banner shown, buzz stopped. medium → low: nothing.
10. `connected=false`: content frozen, dot visible with "Reconnecting" label.
11. System back while Warning up: still shown.
12. `disableAnimations: true`: Warning fully shown after one pump.
13. Hang up tapped: `onHangUp` called once.
14. Every fixture validates against `stage-update.schema.json`.

## 10. Decisions (Preston, 27 Oct)
- Q33: the big **Hang up** button on the Warning is approved. She presses it; Jaga never hangs up by itself.
- Q34: `commandEnglish`, `counterMoveEnglish` and `officialNumber` are requested from #1. Until then they are nullable and hidden.
- Q35: one built-in safety-net command, "Letak telefon. Hang up.", only when `command` is null at high risk. Lane D approves the wording.
- Q36: the evidence line is a labelled masked quote ("The caller said"); the credentials Warning shows no evidence.
- Q37: a Caution never buzzes. The buzz always means "look now, it's serious".
- The re-show rule (stage change or risk rise), the TalkBack two-tap dismiss and the command-fit rule are accepted as written.
- Redesign (Preston, 28 Oct): the Warning becomes the Jaga notice (§4). Q38: body text on the Warning is capped at 1.4
  (buttons 1.5). Q39: "This call is fine" moves to the end of the scroll area, still hold-to-confirm. Q40: the counter-move
  length budget (about 90 characters per language) is raised with Lane D separately; no code.
