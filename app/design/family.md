# Family co-pilot: alert (#11) and home (#23)

From `ui-plan.md` §3 and `design-system.md`. The family co-pilot's own phone, in their own app language. Contract:
`contracts/family-alert.schema.json` (draft v0; #1 not landed). The co-pilot may see Spark's free-text `summary` and
masked quotes; the phrase-library rule (ADR 0006) binds the protected user's screens only.

## 1. Point of view
The alert is urgent but never a takeover (plan §3). It borrows the **Caution** amber, not Warning red: amber means "signs
of a scam" on both phones, and red stays the protected user's alone. The memorable element is the **name band**: a
full-bleed amber field at the top with "Mum may be on a scam call" in big type, the same field turning calm blue for the
"may be genuine" follow-up. Everything under it is quiet paper and teal, and the one action is "Call Mum".

## 2. Architecture
```
lib/data/models/family_alert.dart       FamilyAlert.fromJson (v0 fields) + FamilyAlertKind {alert, mayBeGenuine}
lib/data/models/linked_person.dart      LinkedPerson {name, phoneNumber?}  (local link record, written by onboarding)
lib/data/services/alert_push_service.dart  abstract { Stream<FamilyAlert> alerts; Future<FamilyAlert?> launchAlert(); }
                                        FcmAlertPushService (firebase_messaging), FakeAlertPushService (fixtures)
lib/data/services/alert_notifier.dart   abstract { show(FamilyAlert, LinkedPerson); } LocalAlertNotifier, FakeAlertNotifier
lib/data/services/dialer_service.dart   abstract { Future<bool> dial(String? number); } UrlDialerService, FakeDialerService
lib/data/repositories/family_alert_repository.dart  latest alert per callId; merges the follow-up into the same call
lib/features/family/view_models/family_alert_view_model.dart  ChangeNotifier, state = FamilyAlertState
lib/features/family/views/family_alert_screen.dart, views/widgets/name_band.dart, views/widgets/quote_block.dart
```
`FamilyAlertState`: `kind`, `personName`, `stage`, `agency?`, `summary`, `quotes` (0..2), `at`, `canDial` (number known).
A newer push for the same `callId` updates the open screen in place (stage only ever rises; kind may become mayBeGenuine).

## 3. Notification (Android)
- **Delivery:** FCM high-priority **data** message (no `notification` block), so our background handler builds the
  notification and controls channel and actions. Payload proposal for #1: `data: {"familyAlert": "<FamilyAlert JSON>"}`
  (FCM data values must be strings).
- **Channels** (created at first launch): `family_alerts` "Scam alerts", `Importance.max` (heads-up), default sound and
  vibration, `NotificationVisibility.public`, category `message` (no DND bypass). `family_updates` "Call updates",
  `Importance.low` (no heads-up, no sound) for "may be genuine".
- **Content:** (lead's decision, Qi Cai, 3 Nov: stage and agency show; reverts the 2 Nov name-only change.)
  Title `familyNotifTitle` ("Mum may be on a scam call"), body `familyNotifBody` (stage label, plus agency
  when known). Never quotes or summary on the lock screen. Notification id = hash of `callId`, so the second push and the
  follow-up **replace** the first instead of stacking (`onlyAlertOnce: false` on the alert channel so the money push re-rings).
- **Action** `familyNotifCallAction` ("Call Mum"), `showsUserInterface: true`: opens the alert screen with `autoDial`,
  which launches the dialer after the first frame. Returning from the dialer lands on the alert screen.
- **Tap:** opens `FamilyAlertScreen` for that `callId` (payload = the alert JSON; cold start via
  `getNotificationAppLaunchDetails`). Never `fullScreenIntent`.
- **Dialer:** `url_launcher` `tel:` (ACTION_DIAL equivalent): opens the dialer prefilled, the co-pilot presses call. No
  `CALL_PHONE` permission. No number known: opens the dialer empty.

## 4. Alert screen (`FamilyAlertScreen`)
```
Scaffold(surface) > Column
  Expanded > SingleChildScrollView > Column         // the band scrolls with the body (see below)
    NameBand: Material(caution | genuineContainer), bottom radius 28, 3dp cautionEdge rule (alert only)
      SafeArea(bottom:false) > Padding(l24) > Semantics(header, liveRegion) > Column
        Text(familyAlertHeadline | familyGenuineHeadline, headlineMedium, onCaution | onGenuineContainer)
        gap s8, Text(familyAlertTime(at), bodyMedium)
    Padding(l24) > Column
      0 (genuine only) Text(familyGenuineBody, bodyLarge)
      1 StageProgressBar(stage)                         // 6 steps, plain label under it
      2 gap l24, Text(familyAlertAgencyLabel, bodyMedium) + Text(agency, titleLarge)   // hidden if null
      3 gap l24, Text(summary, bodyLarge)
      4 gap l24, Text(familyAlertQuotesLabel, bodyMedium), then per quote: QuoteBlock
          (surfaceContainer, radius 12, 4dp left rule outline, "“…”" bodyLarge, no maxLines)   // hidden if empty
  BottomAction (pinned): [dial-failed message + number], BigButton(icon: call, label: familyAlertCall(name), tone: guarded | genuine)
```
- **The band scrolls, the Call button is pinned.** A long name at text scale 2.0 makes the band taller than the room
  above the button; a pinned band overflowed and pushed the button off screen. The band therefore scrolls with the
  body, and only the Call button stays fixed, so it is always reachable.
- **Long names:** past 12 characters the button reads just "Call" (`familyAlertCallShort`); TalkBack still says the full
  "Call {name}".
- **Phone app will not open:** `familyAlertDialFailed` appears above the button with the number under it (when known),
  so the co-pilot can dial it herself. The next successful tap clears it.
- Order is the scan order in seconds: who and when, how far it got, who they claim to be, what's happening, proof, act.
- **Time:** `at` as local time, `DateFormat.jm(locale)` ("2:04 PM"); today only shows time, older shows date too.
- **Back:** normal `canPop`; a visible back button too, see §12.1.
- **Motion:** one moment. When the follow-up arrives with the screen open, the band cross-fades amber → blue (200 ms,
  instant with `disableAnimations`), and TalkBack announces the new headline.
- **States:** `alert-isolation`, `alert-money` (second push), `alert-credentials`, `no-agency`, `no-quotes`,
  `two-long-quotes`, `may-be-genuine`, `no-number` (button label `familyAlertOpenDialer`, still enabled),
  `bad-payload` (unparseable push: no notification, logged; the screen is never shown with partial data).
  No loading state: the screen is built from the payload already in hand.

## 5. "May be genuine" follow-up
Same layout, band `genuineContainer` / `onGenuineContainer`, no edge rule, icon `Icons.check_circle_outline` before the
headline. Headline `familyGenuineHeadline`, then `familyGenuineBody` above the stage bar. Stage bar stays (stage never
goes down). Quotes hidden. Button `BigButton(tone: genuine)` with the same "Call Mum" label: calling is still fine. No
sound, no heads-up (§3 `family_updates`), and it replaces the earlier notification.

## 6. Co-pilot home, stage timeline, Clear Jaga Pause (#23, sketch)
```
ScreenFrame(title: appTitle)
  ProtectedPersonCard (surfaceContainer, radius 28, padding l24)
    Text(name, headlineMedium) | StatusBadge(familyHomeProtected, guarded, Icons.shield)
    if pauseActive: StatusBadge(statusPauseActive, caution, Icons.pause_circle)
                    OutlinedButton(familyClearPause) → ClearPauseSheet
  gap xl, Text(familyCallsTitle, titleLarge)
  ListView of AlertedCallTile (min 72dp): date + time, agency, StageProgressBar(compact) → StageTimelineScreen
  empty: Text(familyCallsEmpty, bodyLarge)
ClearPauseSheet (modal bottom sheet): Text(familyClearPauseStatement(name), bodyLarge),
  HoldToConfirmButton(label: familyClearPauseHold) → request → sheet closes, badge gone, SnackBar familyPauseCleared
StageTimelineScreen: ScreenFrame(title: familyTimelineTitle(date))
  vertical list, one row per event: time (bodyMedium) | stage label (titleLarge) | risk change badge | masked quote
  bottomAction: BigButton(familyCallHotline(hotline)) ; AppBar action: IconButton(delete, semantics familyTimelineDelete)
    → AlertDialog(familyTimelineDeleteConfirm) → deletes, pops, SnackBar familyTimelineDeleted
```
Settings (app language, unlink) via a visible AppBar icon (§12.2). Genuine calls never appear. Error: list fails to load →
`familyCallsError` + "Try again" (`commonTryAgain`). Clear Jaga Pause fails → sheet stays, `familyClearPauseError`.

## 7. Contract fields → elements
| Element | Field | Status |
|---|---|---|
| headline name | `protectedUserName` (local nickname from the link record wins, see onboarding.md) | in v0 |
| stage bar | `stage` (isolation…credentials) | in v0 |
| agency | `claimedAgency` | in v0 |
| summary, quotes | `summary`, `quotes[0..1]` | in v0 (shown as-is: the server sends `summary` in the co-pilot's app language) |
| time | `at` | in v0 |
| replace / merge per call | `callId` | in v0 |
| amber vs blue | none | **missing**: `kind` (`alert` / `mayBeGenuine`) |
| Call button number | none | **missing**: protected user's phone number; belongs in the link response, not every push |
| pause badge, Clear Jaga Pause | none | **missing**: co-pilot pause status and clear request (`pause.schema.json` is bank-facing, keyed by pause token) |
| alerted calls, timeline | none | **missing**: stage-timeline shape (events: stage, at, risk, source, masked quote) + list + delete |
| "Call 997" | none | **missing**: region pack scam hotline (don't hard-code 997; fixture value until #1) |

**Until #1:** `kind` absent ⇒ `alert`. The `may-be-genuine` gallery fixture is built in Dart (it fails the v0 schema's
`additionalProperties: false`) and is excluded from the schema test until #1 adds `kind`. Phone number comes from the local
`LinkedPerson` fixture. #23 screens run on `FakeFamilyHomeService` fixtures only.

## 8. Copy (`app_en.arb`; ms/zh by flutter-dev)
| Key | English |
|---|---|
| `familyNotifChannelAlerts` / `familyNotifChannelUpdates` | Scam alerts / Call updates |
| `familyNotifTitle` | {name} may be on a scam call |
| `familyNotifBody` / `familyNotifBodyAgency` | {stage}. / {stage}. Says they are from {agency}. |
| `familyNotifGenuineTitle` | {name}'s call may be genuine |
| `familyNotifCallAction` | Call {name} |
| `familyAlertHeadline` | {name} may be on a scam call |
| `familyAlertTime` | Alert at {time} |
| `familyAlertAgencyLabel` | The caller says they are from |
| `familyAlertQuotesLabel` | The caller said |
| `familyAlertCall` | Call {name} |
| `familyAlertOpenDialer` | Open the phone app |
| `familyGenuineHeadline` | {name}'s call may be genuine |
| `familyGenuineBody` | Jaga now thinks this call is less likely to be a scam. You can still call {name} to check. |
| `familyHomeProtected` | Protected |
| `familyClearPause` | Clear Jaga Pause |
| `familyClearPauseStatement` | I've spoken to {name} and checked this transfer is genuine. |
| `familyClearPauseHold` | Hold to clear Jaga Pause |
| `familyPauseCleared` / `familyClearPauseError` | Jaga Pause cleared / Couldn't clear Jaga Pause. Check your internet and try again. |
| `familyCallsTitle` / `familyCallsEmpty` | Alerted calls / No alerted calls in the last 30 days. |
| `familyCallsError` | Couldn't load calls. Check your internet. |
| `familyTimelineTitle` / `familyCallHotline` | Call on {date} / Call {hotline} to report |
| `familyTimelineDelete` / `familyTimelineDeleteConfirm` | Delete / Delete this timeline? It can't be brought back. |
| `familyTimelineDeleted` / `commonTryAgain` | Timeline deleted / Try again |

## 9. Gallery (`lib/debug/entries/family_entries.dart`)
`alert-isolation`, `alert-money`, `alert-credentials`, `alert-no-agency`, `alert-no-quotes`, `alert-long-quotes`,
`alert-no-number`, `may-be-genuine`, `alert-to-genuine` (button flips kind), `notification-test` (calls the real
`LocalAlertNotifier` so the heads-up and lock screen can be checked on the emulator); #23: `home`, `home-pause-active`,
`home-empty`, `home-error`, `clear-pause-sheet`, `timeline`.

## 10. Widget tests (`test/features/family/`), each at 393×852 and again at text scale 2.0
1. alert: headline, stage label, agency, summary, both quotes in that paint and semantics order; Call button visible.
2. Call tapped: `FakeDialerService.dial` gets the fixture number once. `autoDial`: dialled after first frame, once.
3. no-number: label "Open the phone app", dial called with null.
4. no agency / no quotes: those blocks absent, no empty gaps or labels.
5. Two 200-character quotes at scale 2.0: no overflow; body scrolls; Call button stays pinned and fully visible.
6. may-be-genuine: blue band, genuine headline and body, no quotes, Call button genuine tone.
7. Follow-up for the same `callId` with the screen open: headline swaps in place, stage bar unchanged or higher.
8. Older `stage` for the same `callId` arrives late: stage bar does not go down.
9. Notifier: `FakeAlertNotifier` receives one `show` per push, same id for the same `callId`; channel `family_updates` for genuine.
10. Every `family-alert` fixture (except the genuine one, until #1 adds `kind`) validates against the schema.

## 10b. Decisions (Preston, settled)
1. A co-pilot call reaching Mum mid-scam under `*21*` forwarding is deferred to the telephony test in #2/#12; no UI change.
2. The summary is shown as-is, in the co-pilot's app language (the server's job).
3. The protected status screen gets an amber `needsAttention` "Ask your family to check Jaga" state when a permission is lost.
4. PIN: 4 digits, 5 wrong tries, then a 5-minute lockout.
5. Onboarding step 9 is buzz-only.
6. The call-forwarding step has a debug-only "Skip" (`kDebugMode`).
7. The lock-screen notification shows stage and agency, never quotes or summary (lead's decision, Qi Cai, 3 Nov).
8. No battery-optimisation checklist item for now.

#23 deviations (flutter-dev):
9. No `FakeFamilyHomeService`: two interfaces instead, `CopilotPauseService` (isActive, clear) and `TimelineService` (calls, events, delete), each with a Fake only. View models take the services directly (no pass-through repository). `AlertedCall` and `TimelineEvent` reuse v0 fields and are provisional until #1; only the fixtures convert from `FamilyAlert` and `StageUpdate`.
10. Settings (now an AppBar icon, §12.2), opening a screen with the app language list and "Remove {name} from this phone" (confirm dialog, then `OnboardingRepository.reset()`; a failure shows `familyUnlinkError` and stays put). Only this phone forgets: the server is not told, there is no unlink endpoint yet, so no copy promises alerts stop.
11. `StageTimelineScreen` puts its title in the scrolling body, not `ScreenFrame.title`: a long title plus the pinned 997 button overflowed at text x2.0.
12. Clear Jaga Pause has its own `ClearPauseViewModel`, so every sheet opens clean. While busy the hold button becomes a spinner button.
13. The timeline's risk badge shows only where risk differs from the step before (Caution shown / Warning shown / Risk fell back to low); never red. Extra copy keys: `familyTimelineError`, `familyTimelineDeleteError`, `familyTimelineRisk*`, `familyUnlink*`.
14. The Clear Jaga Pause sheet cannot be closed while a request is in flight (`PopScope`, drag off); the timeline likewise blocks Back and a second delete. The sheet's text scrolls and its button stays pinned. The brief's `familyCall997` is `familyCallHotline`.
15. The 997 hotline is `scamHotline` in `lib/data/models/scam_hotline.dart` (no region pack yet). "Genuine calls never appear" is the server's job: the list holds only calls that were alerted.

`FcmAlertPushService` has since merged (see 16); #11 first shipped the `AlertPushService` interface and
`FakeAlertPushService`.

16. FCM data push and anonymous auth wired (28 Oct); server registration of the FCM token waits for contracts v1.
    Foreground pushes use `FirebaseMessaging.onMessage`; background and terminated ones go through
    `familyAlertBackgroundHandler`, which reads the linked person from the onboarding store and shows the notification.
    If Firebase fails to start, bootstrap falls back to the Fakes. A background push does not merge by stage: the
    notification id is per `callId`, so a late lower-stage push can replace a higher one until contracts v1 adds ordering.

## 11. Dependency proposals (own PR, `docs/delivery.md`)
`firebase_core`, `firebase_messaging` (FCM data pushes; needs `google-services.json` from the team's Firebase project),
`flutter_local_notifications` (channels, heads-up, action, launch details; needs `POST_NOTIFICATIONS`), `url_launcher`
(`tel:`; add a `<queries>` intent for `tel` to the manifest). #23 adds nothing new.

## 12. Navigation refinements (4 Nov)
Qi Cai flagged co-pilot navigation as the weak spot; Preston approved these four. No contract change: `live` already
comes from the timeline's `endedAt`, and the alert itself stays in memory in the repository.
The whole co-pilot side (every route, dialog and sheet) caps the system text scale at 1.5 (`copilotMaxTextScale`, set app-wide in
`app.dart`; Preston, 4 Nov). Text above that looks out of place there. The tighter caps below (bar 1.2, wordmark 1.3) stay.

**12.1 The alert screen gets a way out and a way to the timeline.** `CopilotShell` keeps home as the root, so Back on
the alert always lands on home, even after a cold start.
```
NameBand(leading: IconButton(Icons.arrow_back, tooltip familyAlertBack, 56dp, onCaution | onGenuineContainer) → pop)
  ... body as in §4 ...
  6 (last in the scroll) gap l24, BigButton(tone: quiet, icon: Icons.timeline, label: familyAlertSeeTimeline)
BottomAction (pinned, unchanged): [dial failed], BigButton(Call)
```
- The back button sits at the start of the band's top row, above the headline, so it scrolls with the band (the same
  reason as §4: nothing else gets pinned). System Back works everywhere.
- "See what happened" goes at the **end of the scroll**, not beside Call: the pinned area stays a single button at text
  x2.0. It pushes `StageTimelineScreen` for that `callId`, using `AlertedCall.fromAlert(alert)` (promote
  `alertedCallFrom` from `debug/fixtures` to `data/models`; `live: true`, so Delete stays off). Back returns to the alert.
- `FamilyAlertScreen({..., VoidCallback? onSeeTimeline})`: null hides the button (gallery, old tests).
- States: alert, may-be-genuine (the back icon in `onGenuineContainer`), no-number, dial-failed; all keep the timeline button.

**12.2 Settings is a visible icon.** Swap the `PopupMenuButton` for `IconButton(Icons.settings_outlined,
tooltip: settingsTitle)`. Add `iconButtonTheme` to `jaga_theme.dart` with `minimumSize: Size.square(m.minTarget)`, so
every IconButton (this one, the timeline's Delete, 12.1's back) is 56dp. No new copy.

**12.3 Home can reopen a live alert.**
- `FamilyAlertRepository` gains `FamilyAlert? latest(String callId)`, a read of `_latest`, which already holds the merged
  alert per call. It is memory only: it starts empty after the process dies. That's fine; see the fallback.
- `CopilotHomeViewModel` gets the repository injected: it exposes `calls` with the live ones first (newest first, then
  the rest in service order), `heldAlert(callId)`, and listens to `repository.alerts` to `load()` again, so a new push
  shows on home without a notification tap.
- Tap a live call that has a held alert: the shell's existing `_open` (passed as `openAlert`, so the alert route is
  built in one place) opens `FamilyAlertScreen`. A live call with no held alert, or an ended call: `StageTimelineScreen`, as now.
- States: no live call (list as now), one live with an alert, live without an alert (opens the timeline), two live,
  list loading or error (no live row; the notification still opens the alert). The alert screen is never opened with
  partial data (§4).

**12.4 The live tile carries a marker.** In `AlertedCallTile`, if `call.live`: the first row is `StatusBadge(familyCallLiveNow,
BadgeTone.caution, Icons.phone_in_talk)`, then date and time, and so on. The tile border is a 3dp `cautionEdge`
(`Material.shape: RoundedRectangleBorder(side: …)`). The fill stays `surfaceContainer`, because amber
fill belongs to the name band and never red. Semantics: the label starts with "Live now", hint `familyCallLiveOpen` when
an alert will open. At text x2.0 the badge text wraps (`Flexible`); the tile grows, minHeight 72.
  Decision (4 Nov): the badge sits above the date row, not beside the chevron, so it has the tile's full width, and its
  text scale is clamped to 1.9 (only there), because "berlangsung" is still 3dp too wide at x2.0 and would split mid-word.

**Copy** (new keys; `settingsTitle` is reused)
| Key | en | ms | zh |
|---|---|---|---|
| `familyAlertBack` | Back to home | Kembali ke laman utama | 返回主页 |
| `familyAlertSeeTimeline` | See what happened | Lihat apa yang berlaku | 查看通话经过 |
| `familyCallLiveNow` | Live now | Sedang berlangsung | 正在通话 |
| `familyCallLiveOpen` | Opens the alert | Membuka amaran | 打开警报 |

**Gallery** (`family_entries.dart`): add `home-live` (live call with a held alert, at the top), `home-live-no-alert`
(opens the timeline), `home-two-live`; `alert-*` and `may-be-genuine` pass `onSeeTimeline` into the fixture timeline.

**Tests** (393×852, and again at text scale 2.0)
1. `family_alert_screen_test`: back tooltip found, 56dp, pops; "See what happened" pushes the timeline with the alert's
   `callId`; `alert-long-text` at x2.0: Call fully visible and pinned, the timeline button reachable by scrolling, no
   overflow; `onSeeTimeline: null` hides it.
2. `copilot_home_screen_test`: no `PopupMenuButton`; the settings tooltip is found, 56dp, opens settings; the live call
   is first with "Live now"; a tap with an alert opens `FamilyAlertScreen`, without one opens the timeline; an ended
   call opens the timeline; two live at x2.0 don't overflow.
3. `family_alert_repository` test: `latest` returns the merged alert (stage never down), and null for an unknown call.
4. `family_home_view_models_test`: live calls first; a repository push triggers one reload.

**12.5 Co-pilot tabs (bottom bar).** Preston asked for basic tabs. Co-pilot side only: the protected user's app never
gets a bar. It replaces 12.2's settings icon; the `iconButtonTheme` stays.
```
CopilotShell (owns _tab, _home, _settings) → CopilotTabs(index, onSelect, tabs)   views/copilot_tabs.dart, no deps
  PopScope(canPop: index == 0, onPopInvoked: !didPop → onSelect(0))
  Scaffold(body: IndexedStack(tabs), bottomNavigationBar: NavigationBar(height 80, labelBehavior: alwaysShow))
    0 Home      Icons.home_outlined / home        CopilotHomeScreen   (wordmark header)
    1 Calls     Icons.history / history           CopilotCallsScreen  (title familyCallsTitle)
    2 Settings  Icons.settings_outlined / settings  CopilotSettingsScreen (title settingsTitle, no back arrow)
```
- **Home is for "is she safe right now"; Calls is the record.** Home: ProtectedPersonCard (pause, Clear Jaga Pause), then
  every live tile (12.4), then, if none is live, one tile under `familyHomeLastCall`, then `TextButton(familyHomeSeeAllCalls)`
  → `onSelect(1)` (a tab switch, not a push). The full list lives only on Calls (live first, as 12.3). Empty and error
  states move with the list to Calls; Home shows `familyCallsEmpty` in place of the last call, or the error row with
  `commonTryAgain`.
- **One view model, two tabs.** `CopilotHomeViewModel` stays the single owner of calls, the `repository.alerts`
  listener and the reload after the alert closes; it adds `liveCalls` and `lastEnded` getters. Both tabs read it, so
  a push reloads once and both tabs agree. The shell also owns `CopilotSettingsViewModel` now that settings is not a route.
- **No nested navigators.** Timeline, Clear Jaga Pause sheet and the alert push on the root navigator, full-screen over
  the bar. The timeline has its own pinned hotline button, and a bar under it would eat the height text x2.0 needs.
  Back pops to the shell, and `IndexedStack` keeps the tab and its scroll. The family alert stays as it is (urgent, no bar):
  Back returns to the tab that was showing; on a cold start, Home. Android Back on Calls or Settings goes to Home
  first, then leaves the app.
- **Unlink** swaps `CopilotShell` out at the app root, as now, so the bar goes with it. `popUntil(isFirst)` stays harmless.
- **Theme** (`navigationBarTheme` in `jaga_theme.dart`): background `surfaceContainer`, elevation 0; indicator
  `primaryContainer` with `StadiumBorder(side: 2dp primary)`, since the fill alone is too close to the bar; selected icon
  filled + `onPrimaryContainer`; labels `labelMedium` (20sp), selected w600 `onPrimaryContainer` (10.9:1), unselected w400
  `onSurfaceVariant` (about 9:1). Not `primary`: 6.5:1 on the bar misses AAA. Each destination is about 131 × 80dp.
- **Text x2.0:** the bar gets `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.2)` (24sp). 1.3 (26sp) was the first
  choice, but the bold selected "Panggilan" wrapped at 1.3 in ms and pushed the indicator out of the bar.
  Labels are short so ms fits; the full label stays in semantics, which M3 announces as "selected, tab 1 of 3".

Copy: `settingsTitle` is the third label; `familyCallsTitle` stays the Calls page title ("Alerted calls" is too wide).
| Key | en | ms | zh |
|---|---|---|---|
| `familyNavHome` | Home | Utama | 主页 |
| `familyNavCalls` | Calls | Panggilan | 通话 |
| `familyHomeLastCall` | Last alert | Amaran terakhir | 最近警报 |
| `familyHomeSeeAllCalls` | See all calls | Lihat semua panggilan | 查看所有通话 |

**Gallery:** `_home` entries render inside `CopilotTabs` (index 0, fixture tabs); add `calls-many`, `calls-empty`,
`calls-error`, `tabs-settings`. Screenshots: `home-live`, `calls-many`, `tabs-settings` at x1.0 and x2.0, in ms.
**Tests:** `copilot_tabs_test`: three labels shown at 393×852 and at x2.0 in en/ms/zh with no overflow, each ≥ 56dp,
selected flag, Back on tab 1 selects 0, Back on 0 pops. `app_test` co-pilot navigation: no settings icon in the
home app bar; See all calls selects Calls; a Calls tile opens the timeline with no `NavigationBar`, and Back
lands on Calls again; a notification on Calls opens the alert without the bar, and Back lands on Calls; Unlink from
the Settings tab reaches onboarding with no bar. `family_home_view_models_test`: `liveCalls`, `lastEnded`.

`home-live` and `home-live-no-alert` stay identical on purpose: the tile says the call is live, which holds either way,
so only the hint changes (`familyCallLiveOpen` or none). A second look would show a detail Preston can't act on.

**12.6 Home header: the wordmark (Preston, 4 Nov).** Home opens with the teal "Jaga" wordmark, like a letterhead, on paper
and not in a teal band: the `GuardedMasthead` band means "a notice is open" (call, Warning), and Home is the calm place.
Calls and Settings keep their plain titles. A first version also had the launcher seal and a "Keeping watch over calls to
{name}" line; Preston dropped both, so the header is the wordmark only.
```
ScreenFrame(title: null, body: Column[ Semantics(header: true, label: appTitle, JagaWordmark(display, guarded)), gap l24, ProtectedPersonCard ... ])
```
- `JagaWordmarkSize.display` is 32; it keeps its 1.3 clamp (41.6sp max) and hides itself from TalkBack, so the `Semantics`
  header node carries the name. Wordmark `guarded` #0B5D4F on `surface` #FBF8F2 is about 7.4:1 (AAA).
- The header never changes with pause or live state: the card's badges and the live tile say that.
- **Gallery:** every `home-*` entry picks it up; `home-long-name` ("Puan Siti Aminah binti Abdullah") checks the card.
  **Tests** (`copilot_home_screen_test`, 393x852 and x2.0, en/ms/zh): one header node labelled "Jaga"; no app bar; the long
  name at x2.0 has no overflow and the card starts below the wordmark.

**12.7 Which phone is this? (role marker, Preston 4 Nov).** Both roles share one app and one paper-and-teal look, so a
glance can't tell them apart. Fix: one fixed spot, the top end corner of every main screen, says whose phone it is, like
the owner's tag on a letterhead. The co-pilot header stays the wordmark only (12.6); no caption returns.
```
ScreenFrame(role: RoleBadge.family, ...)   new optional slot: first row, Align(end), then gap s8, then title or body
  RoleBadge = StatusBadge(tone: neutral, icon: Icons.family_restroom, label: roleFamily)   core/widgets/role_badge.dart
Home:     [                     (Family)]  /  Jaga (display)  /  card: Mum + Protected ...
Calls:    [                     (Family)]  /  Alerted calls  /  list
Settings: [                     (Family)]  /  Settings  /  language, Remove
```
- Neutral tone on purpose: grey `surfaceContainerHigh` with `onSurface` (AAA) never reads as a status, and teal stays
  "protected", amber "live" and red "Warning". It isn't tappable, so no 56dp target; TalkBack reads it before the title.
- **Card:** unchanged. Preston dropped the "You look after" first line, so the badge alone carries the role.
- Not on the alert, the timeline or the Clear Jaga Pause sheet: those are pushed full-screen from Home and name Mum in
  their own band. The bar stays as it is (12.5); its absence on the protected side is the second cue.
- Text: it follows the 1.5 cap. "Keluarga" at 30sp is about 200dp with icon and padding, so one line on 360dp.

| Key | en | ms | zh |
|---|---|---|---|
| `roleFamily` | Family | Keluarga | 家人 |

**Gallery/tests:** every `home-*`, `calls-*` and `tabs-settings` picks it up; `copilot_tabs_test` finds one "Family"
badge on each tab in en/ms/zh at 393x852 and x1.5, end-aligned, above the header node, no overflow.
