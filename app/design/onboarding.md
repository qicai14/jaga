# Onboarding and protected status (#10)

From `ui-plan.md` §2–3 and `design-system.md`. Done by the family co-pilot, on grandma's phone (protected flow) and on
their own phone (co-pilot flow). No login: Firebase Anonymous Auth runs silently at first launch.

## 1. Point of view
A patient checklist, not a carousel. Each step is one page with one job and one full-width primary button at the bottom.
The one memorable moment is step 8: the 6-digit **link code** as the only centred element in the app, in `linkCode` type
(48sp, two groups of three: "482 913"). Steps are numbered because they are a real sequence.

## 2. Architecture
```
lib/data/models/onboarding_progress.dart   role, step, language, personName, pinSet, registration?, link?
lib/data/models/registration.dart          {protectedUserId, jagaLineNumber, pauseToken, linkCode}   (no contract yet)
lib/data/services/onboarding_api_service.dart  abstract register(), join(code, name), copilots(); + Fake (fixtures)
lib/data/services/device_setup_service.dart   abstract check(): Map<SetupItem, bool>; fix(SetupItem); isXiaomi
                                           MethodChannelDeviceSetupService (Kotlin, MainActivity) + Fake
lib/data/services/key_value_store.dart    KeyValueStore: SecureStore (flutter_secure_storage, Keystore-backed) + InMemoryStore for tests
lib/data/repositories/pin_repository.dart  co-pilot lock: salted SHA-256 hash, wrong-try count and lock expiry, all in SecureStore
lib/data/repositories/onboarding_repository.dart
lib/features/onboarding/view_models/onboarding_view_model.dart     one VM, steps as an enum per role
lib/features/onboarding/views/onboarding_screen.dart, views/steps/<step>_step.dart
lib/features/onboarding/views/protected_home_screen.dart, protected_settings_screen.dart
lib/core/widgets/pin_pad.dart              shared by step 6 and the settings gate
```
**Frame for every step:** `ScreenFrame` with an AppBar (back arrow 56dp, title `onboardingStepOf(n, total)`), a 6dp
segmented `LinearProgressIndicator` (guarded on `surfaceContainerHigh`) under it, `headlineMedium` step title, body
scrolls, `bottomAction` = `BigButton(onboardingContinue)`, disabled until the step is valid.

**Back:** the AppBar arrow and system back go to the previous step (values kept). Step 1 back exits the app. After
registration (end of step 3) the role and region are locked: going back to step 1–3 shows them read-only. Step 10 has no
back. **Persistence:** after every Continue, `OnboardingProgress` is saved; a relaunch resumes at the saved step. Step 4
is re-checked on resume, never trusted from storage. Done keeps the progress and sets its `complete` flag (the status screen and settings read the registration and language
from it); reset replaces it with a fresh one. The progress is in `SecureStore` (it holds the registration), and an
unreadable or corrupt record means a fresh start. The PIN hash is not strong on its own (4 digits can be guessed
offline): the protection is the lockout and the Keystore.

## 3. Protected flow (10 steps)
| # | Step | Content and states |
|---|---|---|
| 1 | Role | `onboardingRoleTitle`; two large choice cards (min 96dp, `surfaceContainer`, radius 28, selected = 3dp `primary` border + check): `onboardingRoleProtected` / `onboardingRoleCopilot`, each with a one-line body. Same step in both flows |
| 2 | Command language | Radio list, each option in its own script ("Bahasa Melayu", "English", "中文", "தமிழ்"), Malay preselected. The app switches language live on selection |
| 3 | About her | Text field `onboardingNameLabel` (her name, as the family calls her, max 30), then region row "Malaysia" with `onboardingRegionInfo` (read-only). Continue = **register**: button shows a spinner and "Setting up…"; error → inline `onboardingNetworkError` + retry |
| 4 | Phone permissions | Checklist (§5). Continue enabled when every required item is green |
| 5 | Call forwarding (a "Skip" `TextButton` appears only under `kDebugMode`, decision 6) | Body `onboardingForwardBody`; the code `*21*+1 555 010 0199#` in `officialNumber` style inside a `surfaceContainer` box; `BigButton(onboardingDialNow)`; secondary `OutlinedButton(onboardingCheckForwarding)` dials `*#21#`; Continue labelled `onboardingForwardDone` ("I've dialled it"). No live tick: Android can't read forwarding state |
| 6 | Co-pilot lock PIN | `PinPad`, 4 digits. Sub-state set → confirm (`onboardingPinConfirm`); mismatch → `onboardingPinMismatch`, back to set. Body `onboardingPinBody` explains why |
| 7 | Pause token | Token in a `surfaceContainer` box, `bodyLarge`, selectable, shown in groups of 4 (copy raw). `onboardingPauseBody`. Buttons: `commonCopy` (SnackBar `commonCopied`), `commonShare` (`share_plus`) |
| 8 | Link code | Code centred, `linkCode`, Semantics reads digits singly. `commonShare` with `onboardingLinkShareText`. Below: live list "Joined so far" (`onboardingJoined`), polled every 5 s while visible; empty = `onboardingJoinedNone`. Continue never waits for a join |
| 9 | Feel the buzz | `onboardingBuzzBody`; `BigButton(onboardingBuzzButton, icon: vibration)` → `Buzzer.playOnce()`; Continue enabled after one play. Buzz only, no sound (decision 5) |
| 10 | Done | Big guarded check, `onboardingDoneProtected`; `BigButton(onboardingFinish)` → status screen (replaces the stack) |

**Dial now:** `Uri(scheme: 'tel', path: '*21*$jagaLine#')` must produce a string ending in `%23`
(`tel:*21*+15550100199%23`). An unencoded `#` starts a URI fragment and the dialer silently drops it, so the code wouldn't run. Test the string.
`url_launcher` opens ACTION_DIAL-equivalent: the co-pilot presses call. Strip spaces from the number before building.

## 4. Co-pilot flow (5 steps)
1 Role (as above). 2 App language (same list, default = phone language if supported, else ms). 3 Link code: six
single-digit boxes (one `TextField`, `keyboardType: number`, autofill off), `onboardingJoinCode`, then on a valid code a
sub-state asks `onboardingYourName` (shown to her) and `onboardingCallHer` (prefilled with her name, local only, used in
alerts). Errors inline under the boxes, `error` colour, in a `Semantics(liveRegion)`: `onboardingCodeWrong`,
`onboardingCodeExpired`, `onboardingCopilotsFull`, `onboardingNetworkError`. 4 Notifications: one checklist row (§5
item a) plus the `family_alerts` channel enabled; `TextButton(onboardingNotNow)` allowed (home then shows an "Alerts are
off" card). 5 Done: `onboardingDoneCopilot(name)` → family home.

## 5. Phone permissions checklist (step 4)
Row: icon (`check_circle` guarded / `error_outline` `error`), title `titleLarge`, one-line why `bodyMedium`, and a `Fix`
`OutlinedButton` (min 56dp) while red. Re-check on `AppLifecycleState.resumed` (the VM implements
`WidgetsBindingObserver`); the tick appears with a `liveRegion` announcement.
| Item | Check | Fix |
|---|---|---|
| a Notifications (13+) | `Permission.notification` | request; if permanently denied `Settings.ACTION_APP_NOTIFICATION_SETTINGS` + `EXTRA_APP_PACKAGE` |
| b Microphone | `Permission.microphone` | request; else `ACTION_APPLICATION_DETAILS_SETTINGS` (`package:` uri) |
| c Full-screen alerts (14+) | `NotificationManager.canUseFullScreenIntent()` (API 34+; below = green) | `Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT` (`package:` uri) |
| d Calling account | `twilio_voice` phone account registered and enabled | register, then `TelecomManager.ACTION_CHANGE_PHONE_ACCOUNTS` |
| e Xiaomi autostart | only if manufacturer is xiaomi/redmi/poco; can't be read | component `com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity`, fallback app details; then a manual `onboardingFixedIt` tick |
Item d is a fake (always red with Fix → "Available after #12", `onboardingAfterCallSetup`, counted as done) until #12
adds `twilio_voice`. Samsung and some OEMs hide the calling-account toggle: if the intent fails, open app details.

## 6. Protected status screen and settings gate
```
ScreenFrame(no title) > GestureDetector(onLongPress: whole body) > Column
  Icon(check_circle, 96, guarded), gap l24, Text(statusProtected, displaySmall)
  gap xl, Text(statusFamilyLabel, bodyMedium), Text(names joined with ", ", titleLarge)   // empty: statusFamilyNone
```
Long-press (anywhere, default duration) → bottom sheet `PinPad` titled `settingsPinTitle` with `commonCancel`. Wrong PIN
→ `settingsPinWrong`; 5 wrong → locked 5 min (`settingsPinLocked`). Right PIN → `ProtectedSettingsScreen`: language,
forwarding (step 5 view), pause token (step 7 view), link code (step 8 view), reset (`HoldToConfirmButton`
`settingsReset`, unregisters, back to step 1). Nothing on the status screen hints at the gesture (the co-pilot knows).
If a step-4 check fails on resume, the screen shows the `needsAttention` state (decision 3): amber icon,
`statusNeedsFamily`, same layout.

## 7. Server data (no contract yet; all **missing**, ask #1 for `registration` and `link` schemas)
- `register(region, commandLanguage, personName, fcmToken)` → `protectedUserId`, `jagaLineNumber`, `pauseToken`,
  `linkCode`, `linkCodeExpiresAt?`.
- `copilots()` → names (status screen, step 8).
- `join(linkCode, copilotName, fcmToken)` → `protectedUserName`, `protectedUserPhone` (family Call button), or an error
  `invalid | expired | full`.
- **Contract note for #1:** `checkLinkCode(code)` (the app calls it before asking for names, so the co-pilot sees
  invalid/expired/full first) must be rate-limited server-side and must **not** consume the code; only `join` does.
  Without a limit it lets anyone guess six-digit codes.
**Until then:** `FakeOnboardingApiService` returns fixtures (Jaga line `+15550100199`, token `JAGA-7Q4M-2KXP-9D3F`, code
`482913`; join code `000000` = full, `111111` = expired, others wrong). Fixtures are Dart, not JSON, until a schema
exists (no schema test).

## 8. Copy (`app_en.arb`; ms/zh/ta by flutter-dev)
| Key | English |
|---|---|
| `onboardingStepOf` / `onboardingContinue` | Step {step} of {total} / Continue |
| `onboardingRoleTitle` | Who is this phone for? |
| `onboardingRoleProtected` / `…ProtectedBody` | The person Jaga protects / Calls to this phone will ring in Jaga. |
| `onboardingRoleCopilot` / `…CopilotBody` | A family co-pilot / Get alerts about someone you look after. |
| `onboardingLanguageTitle` / `onboardingAppLanguageTitle` | Which language should warnings use? / Choose your language |
| `onboardingAboutTitle` / `onboardingNameLabel` | About her / What does the family call her? |
| `onboardingRegionInfo` | Region: Malaysia. Jaga uses Malaysia's official numbers. |
| `onboardingSettingUp` / `onboardingNetworkError` | Setting up… / Can't reach Jaga. Check the internet and try again. |
| `onboardingPermissionsTitle` / `onboardingFix` / `onboardingFixedIt` | Phone permissions / Fix / I've done this |
| `onboardingPerm{Notifications,Microphone,FullScreen,CallingAccount,Autostart}` | Notifications / Microphone / Full-screen alerts / Calling account / Start automatically |
| `onboardingPerm…Why` (one each) | Shows alerts. / Lets you talk on calls through Jaga. / Lets the warning fill the screen. / Lets calls ring in Jaga. / Keeps Jaga running on Xiaomi phones. |
| `onboardingAfterCallSetup` | Set up later with calls |
| `onboardingForwardTitle` / `onboardingForwardBody` | Forward calls to Jaga / Dial this code once. Calls to this phone will then ring in Jaga. |
| `onboardingDialNow` / `onboardingCheckForwarding` / `onboardingForwardDone` | Dial now / Check forwarding / I've dialled it |
| `onboardingPinTitle` / `onboardingPinBody` | Set the co-pilot lock / Only family can change Jaga's settings with this PIN, so a caller can't talk her into switching it off. |
| `onboardingPinConfirm` / `onboardingPinMismatch` | Enter the PIN again / The PINs don't match. Set it again. |
| `onboardingPauseTitle` / `onboardingPauseBody` | Pause token / Give this to your bank so it can hold transfers during a scam call. |
| `commonCopy` / `commonCopied` / `commonShare` / `commonCancel` | Copy / Copied / Share / Cancel |
| `onboardingLinkTitle` / `onboardingLinkBody` | Link code / Up to 3 family members can enter this code in their own Jaga app. |
| `onboardingLinkShareText` | Open Jaga, choose "A family co-pilot" and enter {code} to get alerts about {name}. |
| `onboardingJoined` / `onboardingJoinedNone` | Joined so far / No one yet |
| `onboardingBuzzTitle` / `onboardingBuzzBody` / `onboardingBuzzButton` | Feel the buzz / When the phone buzzes like this during a call, look at the screen. / Feel the buzz |
| `onboardingDoneProtected` / `onboardingFinish` | Jaga is set up. / Finish |
| `onboardingJoinCode` / `onboardingYourName` / `onboardingCallHer` | Enter the 6-digit code / Your name / What do you call her? |
| `onboardingCodeWrong` / `onboardingCodeExpired` | That code doesn't match. Check the 6 digits. / This code has expired. Ask for a new one. |
| `onboardingCopilotsFull` | 3 family co-pilots are already linked. One must unlink before you can join. |
| `onboardingNotifTitle` / `onboardingNotNow` / `onboardingDoneCopilot` | Allow alerts / Not now / You'll get alerts about {name}. |
| `statusFamilyLabel` / `statusFamilyNone` / `statusNeedsFamily` | Your family / No family linked yet / Ask your family to check Jaga |
| `settingsPinTitle` / `settingsPinWrong` / `settingsPinLocked` | Enter the co-pilot lock / Wrong PIN / Too many tries. Wait 5 minutes. |
| `settingsReset` | Hold to reset Jaga |

## 9. Gallery (`lib/debug/entries/onboarding_entries.dart`)
One entry per step and sub-state: `role`, `language`, `about`, `about-loading`, `about-error`, `perms-all-red`,
`perms-mixed`, `perms-xiaomi`, `perms-all-green`, `forwarding`, `pin-set`, `pin-confirm`, `pin-mismatch`, `pause-token`,
`link-code`, `link-code-joined-3`, `buzz`, `done`; co-pilot: `join-empty`, `join-wrong`, `join-expired`, `join-full`,
`join-names`, `notifications`, `copilot-done`; `status`, `status-no-family`, `status-needs-attention`, `pin-gate`,
`pin-locked`, `settings`.

## 10. Widget tests (`test/features/onboarding/`), each at 393×852 and again at text scale 2.0
1. Each step: title, body and Continue visible; no overflow; Continue reachable (pinned) at 2.0.
2. Progress text "Step n of 10" / "of 5" matches the step; back returns to n-1 with values kept.
3. Relaunch with saved progress at step 6 opens step 6; step 4 re-runs `check()`.
4. Permissions: Continue disabled while any required item is red; resume event with the fake now green ticks it.
5. Dial now: `FakeDialerService` gets a URI whose string ends in `%23` and contains `*21*`.
6. PIN mismatch returns to set with the error; match stores a hash (never the digits).
7. Link code: rendered "482 913", Semantics reads digits singly; Share gets the text with code and name.
8. Feel the buzz: `FakeBuzzer.playOnce` called once; Continue enabled after.
9. Join: `000000` shows the 3-co-pilots error in a live region; valid code moves to the names sub-state.
10. Status: long-press opens the PIN sheet; wrong ×5 locks; right PIN opens settings. Back from settings returns to status.

## 11. Dependency proposals (own PR)
`shared_preferences`, `flutter_secure_storage`, `crypto` (PIN hash), `permission_handler`, `android_intent_plus`
(settings intents, Xiaomi component), `device_info_plus` (SDK int, manufacturer), `share_plus`, `url_launcher` (shared with
family), `firebase_auth` (+ `firebase_core`). Kotlin: a `jaga/device_setup` MethodChannel for `canUseFullScreenIntent`.
Manifest: `USE_FULL_SCREEN_INTENT`, `RECORD_AUDIO`, `POST_NOTIFICATIONS`.

## 12. Decisions (settled with Preston)
1. Co-pilot reachability under `*21*` forwarding (calls to the protected phone divert to the Jaga line) is deferred to telephony #2/#12.
2. The family summary is shown in the co-pilot's app language.
3. The protected status screen has an amber `needsAttention` state, "Ask your family to check Jaga" (`statusNeedsFamily`), shown when a step-4 permission check fails on resume.
4. The PIN is 4 digits. After 5 wrong tries it locks for 5 minutes.
5. Step 9 is buzz-only (no sound).
6. The call-forwarding step has a "Skip" that appears only under `kDebugMode`.
7. The lock-screen notification shows the stage and agency.
8. No battery-optimisation item in the permissions checklist.
9. Accepted deviations from the first draft of this brief:
   - `checkLinkCode(code)` is a separate call from `join` (see the contract note in section 7).
   - Progress is kept with a `complete` flag, not cleared (section 2).
   - The calling-account row is neutral (clock icon, "Set up later with calls", no Fix), not red: it can't be fixed until #12.
   - On Xiaomi, Redmi and POCO the autostart row blocks Continue until the family ticks "I've done this".
   - The forwarding code is shown without spaces (`*21*+15550100199#`) and shrinks to fit one line.
   - A matching PIN moves on to the next step by itself.
   - A co-pilot starts in the phone's language when Jaga supports it, otherwise Malay.
   - A linked co-pilot has no back from step 4 (the code is used up); on the names sub-step, back returns to the code.
   - The microphone row says "Lets you talk on calls through Jaga": the server hears the caller (ADR 0002), the phone mic carries her own voice.
