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
Positioned(top) > Semantics(liveRegion, container) > Material(color: caution, bottom radius 20, 3dp cautionEdge rule)
  SafeArea(bottom: false) > Padding(l24, m16) > Column
    Row: Icon(Icons.hearing, 32, onCaution) | gap s8 | Expanded(Text(cautionBannerText, titleLarge, onCaution))
    ReconnectingDot (end of row, when reconnecting)
    gap m16
    HoldToConfirmButton(tone: onCaution outlined, label: warningDismissLabel, secondLabel: English, small: height 56)
```
Order: icon + text, then dismiss. Slides down 200 ms on appear (instant if animations off). The call controls below stay
usable; at text scale 2.0 the banner may grow to ~40% of the height, never more (the text wraps, nothing scrolls).

## 4. Warning (high), full screen
```
AnnotatedRegion(SystemUiOverlayStyle.light) > PopScope(canPop: false) > Semantics(scopesRoute, namesRoute,
  label: warningSemanticsLabel, liveRegion) > Material(color: warning) > SafeArea > Padding(h l24) > Column
  1 Row: Icon(call_end | pan_tool for credentials, 40, onWarning) ... ReconnectingDot(onWarning 60%)
  2 Flexible(flex 5) command region, LayoutBuilder:
      ShrinkToFitText(content.command, JagaTextStyles.command, min 32, onWarning)
      gap s8
      Text(content.commandEnglish, commandEnglish)          // only if it differs from the command
  3 Divider(2dp, onWarning 40%)
  4 Flexible(flex 4) SingleChildScrollView > Column:
      Text(content.counterMove, bodyLarge, onWarning)
      gap m16
      Text(warningOfficialNumberLabel(agency) | warningOfficialNumberLabelNoAgency, bodyMedium, onWarning)
      Text(content.officialNumber, officialNumber, warningNumber)   // plain text, not a button
      gap l24
      Text(warningEvidenceLabel, bodyMedium) + Text("“${evidence[0]}”", bodyLarge italic, maxLines 3, ellipsis)  // never on credentials (Q36)
  5 BigButton(tone: onWarning, icon: call_end, label: warningHangUp) → onHangUp
  6 gap s8, HoldToConfirmButton(tone: onWarning outlined, height 56, label + English second line)
```
- **Fit rule:** the command region never scrolls. `ShrinkToFitText` steps from 52sp × text scale down to 32sp. If it still
  doesn't fit at 32, the command region takes the space it needs and only region 4 scrolls.
- **English fallback:** if a phrase is missing in her language the server sends English (#1); when `command` equals
  `commandEnglish` it is shown once. Same for the counter-move.
- **Motion:** one moment. The red field wipes down from the top in 200 ms, then the command fades in (100 ms). Off when
  `disableAnimations`.
- **Back:** predictive back gesture does nothing while the Warning is up. Only the hold-to-dismiss closes it.

## 5. Copy (`app_en.arb`; ms/zh/ta by flutter-dev)
| Key | English | Notes |
|---|---|---|
| `cautionBannerText` | This call has signs of a scam | glossary wording |
| `warningSemanticsLabel` | Scam warning | route name for TalkBack |
| `warningOfficialNumberLabel` | {agency}'s official number | `agency` = `claimedAgency` |
| `warningOfficialNumberLabelNoAgency` | Official number | |
| `warningEvidenceLabel` | The caller said | |
| `warningHangUp` | Hang up | |
| `warningDismissLabel` | This call is fine | ms: "Panggilan ini selamat" |
| `warningDismissHint` | Hold for 2 seconds | semantics hint |
| `warningDismissConfirmHint` | Tap again to confirm this call is fine | TalkBack two-step |
| `warningCommandFallback` | Letak telefon. Hang up. | only if `command` is null at high; Lane D (Joshua) to approve the wording (Q35) |
| `callReconnecting` | Reconnecting | semantics only, never shown as text |

## 6. Buzz and TalkBack
- **Pattern** (`vibration`, amplitude 255): `[0, 120, 80, 120, 80, 120, 80, 700]` then 1,000 ms gap = 2.3 s per cycle, three
  short then one long. Repeats until: `looked` (proximity far for 1 s), any touch on the Warning, dismiss, step-down, call
  end, or 60 s. Re-armed by the next re-show or command change. Caution: no buzz. No sound into the call.
- **TalkBack:** the Warning is a new route scope with `liveRegion`, and the view model also calls
  `SemanticsService.sendAnnouncement` with "command. commandEnglish". Focus order follows §4 (1→6). The official number has a
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
4. high, 2.0 scale and a 60-character command: command `fontSize` ≥ 32 effective, no overflow errors, no scroll in region 2.
5. high-credentials: credentials command and hand icon; no evidence line even if `evidence` is non-empty.
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
