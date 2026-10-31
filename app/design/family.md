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
- **Content:** title `familyNotifTitle` ("Mum may be on a scam call"), body `familyNotifBody` (stage label, plus agency
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
- **Back:** normal `canPop`. Back goes to the co-pilot home (or exits if it was a cold start with no home yet).
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
Settings (app language, unlink) via the AppBar overflow. Genuine calls never appear. Error: list fails to load →
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
7. The lock-screen notification shows stage and agency, never quotes or summary.
8. No battery-optimisation checklist item for now.

#23 deviations (flutter-dev):
9. No `FakeFamilyHomeService`: two interfaces instead, `CopilotPauseService` (isActive, clear) and `TimelineService` (calls, events, delete), each with a Fake only. View models take the services directly (no pass-through repository). `AlertedCall` and `TimelineEvent` reuse v0 fields and are provisional until #1; only the fixtures convert from `FamilyAlert` and `StageUpdate`.
10. Settings is one "Settings" item in the AppBar overflow, opening a screen with the app language list and "Remove {name} from this phone" (confirm dialog, then `OnboardingRepository.reset()`; a failure shows `familyUnlinkError` and stays put). Only this phone forgets: the server is not told, there is no unlink endpoint yet, so no copy promises alerts stop.
11. `StageTimelineScreen` puts its title in the scrolling body, not `ScreenFrame.title`: a long title plus the pinned 997 button overflowed at text x2.0.
12. Clear Jaga Pause has its own `ClearPauseViewModel`, so every sheet opens clean. While busy the hold button becomes a spinner button.
13. The timeline's risk badge shows only where risk differs from the step before (Caution shown / Warning shown / Risk fell back to low); never red. Extra copy keys: `familyTimelineError`, `familyTimelineDeleteError`, `familyTimelineRisk*`, `familyUnlink*`.
14. The Clear Jaga Pause sheet cannot be closed while a request is in flight (`PopScope`, drag off); the timeline likewise blocks Back and a second delete. The sheet's text scrolls and its button stays pinned. The brief's `familyCall997` is `familyCallHotline`.
15. The 997 hotline is `scamHotline` in `lib/data/models/scam_hotline.dart` (no region pack yet). "Genuine calls never appear" is the server's job: the list holds only calls that were alerted.

`FcmAlertPushService` is a follow-up that waits for the team's Firebase project; #11 ships the `AlertPushService`
interface and `FakeAlertPushService` only.

## 11. Dependency proposals (own PR, `docs/delivery.md`)
`firebase_core`, `firebase_messaging` (FCM data pushes; needs `google-services.json` from the team's Firebase project),
`flutter_local_notifications` (channels, heads-up, action, launch details; needs `POST_NOTIFICATIONS`), `url_launcher`
(`tel:`; add a `<queries>` intent for `tel` to the manifest). #23 adds nothing new.
