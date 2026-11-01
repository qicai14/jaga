# Call: incoming Jaga line call (#12)

From `ui-plan.md` §2, `design-system.md`, `warning.md` and the spike (`spike-twilio-voice.md`, branch
`preston/spike-twilio-voice`). Protected user's phone only. Decision (Preston, 28 Oct): **accept the native Android ring
screen**. `twilio_voice` (git ref `f0522381` until 0.5.1) uses a system-managed ConnectionService, so the phone's dialer
draws ringing and answer. Ours: the in-call screen after answer, the Caution/Warning on it, and our notifications.

## 1. Point of view
**The guard stays in the room.** No dialer clone (no dark screen, no avatar circle, no centred stack of round buttons). The
in-call screen is the same warm paper as the rest of Jaga, left-aligned, almost empty, under a deep teal **guarded
masthead** (the band the Warning already uses). That band is the one memorable thing: it sits in the same place on the call
screen and on the Warning, so a Warning reads as the same notice unfolding, not a new app. No looping motion, nothing pulses.

## 2. At ring (native, not ours)
- The OEM dialer draws the ring/answer screen, over the lock screen, with the system ringtone. We can't style it, set its
  language or enlarge its buttons. It looks like any phone call: familiar to her, which is good.
- What we can influence (Lane A, server TwiML, see §9): the number shown (`<Dial callerId>` = the original caller's number)
  and `__TWI_CALLER_NAME` (the same number, formatted, never "Jaga" or a guess at who it is). Most dialers add "via Jaga"
  from the calling-account label. A missed or declined call shows nothing from Jaga.

## 3. In-call screen (after answer)
```
PopScope(canPop: false, onPopInvoked: back rule) > WarningOverlay(vm: warningVm, onHangUp: vm.hangUp,
 child: Material(surface) > Column
  1 GuardedMasthead (core; extracted from warning_screen): JagaWordmark(large, onGuarded) + Text(callProtecting,
      titleMedium, onGuarded) + ReconnectingDot (stage stream only). Min height 56, full bleed under the status bar
  2 Padding(l24, top xl32) > Column(start)
      FittedBox(scaleDown) > Text(callerLabel, headlineMedium, onSurface, tabular)   // one line, never wraps
      gap s8; Semantics(liveRegion) > Text(status line, bodyLarge, onSurfaceVariant)  // timer or state text
  3 Spacer
  4 Padding(l24, v16) > Column: MuteToggle; gap m12; SpeakerToggle; gap m16; BigButton(hangUp tone, call_end, callHangUp, maxTextScale 1.5))
```
- **Speaker toggle (kept, justified):** on speaker she is looking at the screen, so a Warning is seen at once; many elderly
  users already call on speaker. Full width, 64dp, `OutlinedButton` shape: icon `volume_up`, label `callSpeaker`, trailing
  `callSpeakerOn/Off`; on = `primaryContainer` fill + 3dp `primary` border. Semantics: toggle button with checked state.
- **Mute: kept (Preston, 1 Nov), and its state must be impossible to miss.** Same 64dp full-width shape as Speaker, above it.
  - Off: outlined, icon `mic`, label `callMute`, trailing `callMuteOff`.
  - On: the whole button turns the hang-up red fill with white text, icon `mic_off`, label `callMuted` ("Muted: the caller
    can't hear you"). A same-red strip also appears under the masthead with the same words, so it shows even when she
    only glances at the top. Tapping the strip or the button unmutes.
  - Semantics: toggle button with checked state; announces `callMuted` / `callUnmuted` in a live region on change.
  - Mute is never changed by Jaga: a Warning or Caution keeps it as is, and it resets to off at the next call.
- **Timer: kept**, `mm:ss` from the `connected` event, so she sees the call is live. Semantics `callTimerSemantics`.
- **Ear:** while speaker is off and the screen is ours, hold a proximity screen-off wake lock (dialers do this; once our
  activity is in front the dialer's lock is gone). Released on speaker on, end, or background. Pending trial on a phone.

| Phase | Status line | Controls |
|---|---|---|
| connecting (answered, not connected) | `callConnecting` | mute and speaker disabled, Hang up enabled |
| active | timer | both |
| reconnecting (call audio dropped) | `callReconnectingAudio` (text: her audio is affected, she must know) | both |
| ended | `callEnded` + final `mm:ss` | both replaced by `BigButton(callDone, guarded)`; auto-return after 3 s |
| failed (answered, ended before connected) | `callFailed` + body `callFailedBody` | `BigButton(callDone)` |
| idle on open (stale launch) | none | pop at once to the status screen |

The stage stream dropping is **not** the call reconnecting: it stays the silent dot (warning.md). **Ended:** returns to the
status screen, or to the after-call reassurance (build order 8) when `warningVm` showed a Warning this call.

**Caution and Warning:** `WarningOverlay` wraps the body, unchanged. The banner covers the masthead (it carries its own
wordmark); the Warning fades in over the whole screen with its masthead in the same position. Both are visual and
vibration only: no audio focus, no sound, mic and speaker route untouched. The Warning's Hang up calls the same
`CallService.hangUp()`. On a new `callId` or end, `warningVm` resets (warning.md §2).

**Back:** while the Warning is up, nothing (warning.md). Otherwise back sends the app to the background (`moveTaskToBack`)
and the call goes on, like a dialer. In ended/failed, back returns to the status screen. Launcher icon or our notification
reopen the in-call screen while a call is active (the router checks `CallRepository` on resume).
**Lock screen:** while a call is active the activity sets `showWhenLocked` + `turnScreenOn`; only this screen and the
Warning are reachable, Hang up works without unlocking. Cleared at end, so leaving the call lands behind the keyguard.

## 4. Answered from the native screen while Jaga is in the background
**Trial result (31 Oct, 5 real calls, emulator Android 17; spike doc §8):** answered while Jaga is in the background, the
mic is silenced at once (`App op 27 missing, silencing record`): no error, the caller hears nothing, reproducible. Once our
activity comes to the front the mic is unsilenced within 20 ms, and it stays live if she leaves the app afterwards. So
**bringing our activity forward at answer is required, not optional.** The plugin also turns speaker on at ring: set the
speaker state explicitly at answer.
- The plugin does not bring our activity forward. `JagaApplication` (Kotlin) registers a process-wide local receiver for
  `TVNativeCallActions.ACTION_ANSWERED` (the ConnectionService keeps the process alive even with Flutter not running).
- On answer it posts a **full-screen-intent** notification (channel `jaga_call`, category CALL, ongoing, `callNotification*`
  copy) opening `MainActivity` with `jaga.route=call`. Background activity starts are blocked on Android 10+, so FSI is the
  route: on the lock screen it opens the activity; unlocked it shows a heads-up she can tap. Cancelled once we are in front.
- **#316 mitigation:** at ref `f0522381` the plugin re-issues `startForeground` with the microphone type when our activity
  resumes during a call (`ACTION_REFRESH_FOREGROUND_SERVICE_TYPES`). Bringing the activity forward at answer is therefore
  the fix (confirmed by the trial).
- **Open risk, unlocked phone:** the trial brought the activity forward from adb, which is always allowed. From the app,
  Android 10+ blocks background activity starts, and an FSI on an unlocked phone only shows a heads-up she must tap, so the
  mic stays dead until she taps it. Build order in #12: (1) try `startActivity` straight from the answer receiver and check
  logcat for a BAL allow/deny line; (2) if denied, ask for "Display over other apps" (`SYSTEM_ALERT_WINDOW`), which permits
  background activity starts, as one more row in step 4; (3) keep the FSI for the lock screen. Re-test with a real call.
- If FSI is denied (step 4 row c red), the dialer's own in-call screen stays; the Warning then uses the warning.md fallback.
- The plugin's own foreground notification ("Voice Calls", English, tap target broken) can't change without a fork: noted.

## 5. Onboarding addition: "Allow Jaga to take calls" (in step 4, no new step)
Step count stays 10. Step 4's checklist becomes real for calls; the neutral "Set up later with calls" row is retired.
Row order (calls first): **Phone calls** (new), Microphone, **Calling account** (now real), Notifications, Full-screen alerts,
Xiaomi autostart. Continue needs every row green.
| Row | Check | Fix |
|---|---|---|
| Phone calls (`SetupItem.phoneCalls`) | `READ_PHONE_STATE`, `READ_PHONE_NUMBERS`, `CALL_PHONE` all granted | one request for the three (same Phone group: one system dialog); permanently denied: app details + `onboardingPermOpenSettingsHelp` |
| Calling account | `isPhoneAccountEnabled()` | disabled with `onboardingPermCallingAccountFirst` until Phone calls is green; then `registerPhoneAccount()` (opens the calling-accounts page). Still red on resume: show `onboardingPermCallingAccountHelp`; intent fails (Samsung): `openPhoneAccountSettings()`, then app details |
Recovery: rows re-check on resume as today. **Status screen:** any red row → the existing `needsAttention` state (amber,
`statusNeedsFamily`); no new row on the home screen (she can't fix it). **Settings** (behind the PIN) gains a first section
`onboardingPermissionsTitle` with the same rows, so the co-pilot fixes it there. Keep `rejectCallOnNoPermissions` default
(reject): a call that rings but can't be answered is worse. What the caller then hears is Lane A's (§9).

## 6. Architecture
```
lib/data/models/call_snapshot.dart      CallPhase {idle, ringing, connecting, active, reconnecting, ended, failed},
                                        CallSnapshot {phase, callerLabel?, callId?, connectedAt?, muted, speakerOn}  (app-internal)
lib/data/services/call_service.dart     abstract CallService { Stream<CallSnapshot> snapshots; Future<CallSnapshot> current();
                                        hangUp(); setMuted(bool); setSpeaker(bool); register(accessToken) }  + FakeCallService (scripted)
lib/data/services/twilio_call_service.dart  the only file importing twilio_voice; maps CallEvent -> CallSnapshot
lib/data/services/call_ui_service.dart  `jaga/call_ui` channel: setProximityLock, setShowWhenLocked, moveToBack,
                                        launchedForCall stream  + FakeCallUiService
lib/data/repositories/call_repository.dart  ValueListenable<CallSnapshot>; restores on launch (isOnCall/activeCall);
                                        feeds callId to CallRiskRepository
lib/features/call/view_models/in_call_view_model.dart   ChangeNotifier: phase, timer (1 s Ticker only while active), mute, speaker
lib/features/call/views/in_call_screen.dart, views/widgets/mute_toggle.dart, views/widgets/speaker_toggle.dart
lib/core/widgets/guarded_masthead.dart  shared with warning_screen
lib/debug/entries/call_entries.dart     replaces placeholder_call_screen.dart (warning entries host on InCallScreen)
android: JagaMessagingService.kt (priority 100, spike §5), JagaApplication.kt (§4), MainActivity (`jaga/call_ui`)
DeviceSetupService: + SetupItem.phoneCalls; callingAccount becomes real (both in platformItems)
```
**Event mapping** (`TwilioCallService`): `incoming`/`ringing` → ringing (no screen); `answer` → connecting (+ route to call);
`connected` → active, `connectedAt = now`; `reconnecting` → reconnecting; `reconnected` → active; `callEnded` → ended, or
failed if never connected; `declined`/`missedCall` → idle; `mute/unmute` → `muted`; `speakerOn/Off` → `speakerOn`; `permission` → re-check step 4;
the rest ignored. `callId` from `activeCall.customParams['callId']` (§9). Only the protected role starts `CallService`.
**Push routing:** `JagaMessagingService extends FlutterFirebaseMessagingService`, priority 100: `TwilioVoiceFcm.handleMessage`
takes Twilio invites/cancels natively (works with the app killed); everything else (`data.familyAlert`) falls through to
FlutterFire. Token refresh goes to both, and Dart mirrors it with `setTokens`.
**Dependencies: their own PR first** (docs/delivery.md): `twilio_voice` git ref `f0522381` (to `^0.5.1` when published),
Android `firebase-messaging` aligned with firebase_messaging 17's BOM, `androidx.localbroadcastmanager`. minSdk 29 already
covers the plugin's 26.

## 7. Copy (`app_en.arb`, with ms and zh; flutter-dev adds them, flagged for native review)
| Key | en | ms | zh |
|---|---|---|---|
| `callProtecting` | Protecting this call | Melindungi panggilan ini | 正在保护这通电话 |
| `callConnecting` / `callReconnectingAudio` | Connecting… / Reconnecting the call… | Menyambung… / Menyambung semula panggilan… | 正在接通… / 正在重新连接通话… |
| `callEnded` / `callDone` | Call ended / Done | Panggilan tamat / Selesai | 通话已结束 / 完成 |
| `callFailed` | The call didn't connect | Panggilan tidak bersambung | 电话没有接通 |
| `callFailedBody` | If it matters, they will call again. | Jika penting, mereka akan telefon semula. | 如果有要紧事，对方会再打来。 |
| `callHangUp` | Hang up | Letak telefon | 挂断 |
| `callMute` / `callMuteOff` | Mute / Off | Senyap / Mati | 静音 / 关 |
| `callMuted` | Muted: the caller can't hear you | Disenyapkan: pemanggil tidak dapat dengar anda | 已静音：对方听不到你 |
| `callUnmuted` | Unmuted | Bunyi dihidupkan | 已取消静音 |
| `callSpeaker` / `callSpeakerOn` / `callSpeakerOff` | Speaker / On / Off | Pembesar suara / Hidup / Mati | 扬声器 / 开 / 关 |
| `callTimerSemantics` | Call time {time} | Masa panggilan {time} | 通话时间 {time} |
| `callUnknownCaller` | Unknown number | Nombor tidak dikenali | 未知号码 |
| `callNotificationTitle` / `callNotificationOpen` | Jaga is protecting this call / Open Jaga | Jaga sedang melindungi panggilan ini / Buka Jaga | Jaga 正在保护这通电话 / 打开 Jaga |
| `callNotificationChannel` | Calls | Panggilan | 通话 |
| `onboardingPermPhone` / `…PhoneWhy` | Phone calls / Lets Jaga answer and end calls. | Panggilan telefon / Membolehkan Jaga menjawab dan menamatkan panggilan. | 电话 / 让 Jaga 接听和挂断电话。 |
| `onboardingPermCallingAccountFirst` | Allow phone calls first. | Benarkan panggilan telefon dahulu. | 请先允许电话权限。 |
| `onboardingPermCallingAccountHelp` | Switch on Jaga in the list, then come back. | Hidupkan Jaga dalam senarai, kemudian kembali. | 在列表中打开 Jaga，然后返回。 |
| `onboardingPermOpenSettingsHelp` | Open Permissions, allow {item}, then come back. | Buka Kebenaran, benarkan {item}, kemudian kembali. | 打开"权限"，允许{item}，然后返回。 |
`onboardingAfterCallSetup` is removed. "Jaga" is never translated.

## 8. Contract fields
The in-call screen reads no `contracts/*.schema.json` field itself; the overlay uses `stage-update` as in warning.md.
**Missing** (not in any schema, raise via #1): the `callId` that ties the Twilio call to the stage stream (proposed:
`<Parameter name="callId">` on the `<Client>`), and a Voice access token for `register()` (in `registration` or its own
endpoint). Until then `CallRiskRepository(callId: null)` accepts any call and `FakeCallService` needs no token.

## 9. Needs another lane (Lane A, server TwiML)
`<Dial callerId="{original From}"><Client>` with `__TWI_CALLER_NAME` (formatted number) and `callId` parameters; the
access-token endpoint; what the caller hears if the app rejects the invite (missing permissions) or doesn't answer.

## 10. Widget tests (`test/features/call/`), each at 393×852 and at text scale 2.0
1. active: masthead, caller label on one line, timer, mute, speaker, Hang up visible; no overflow; Hang up above the gesture bar.
2. connecting: `callConnecting`, mute and speaker disabled. reconnecting: `callReconnectingAudio` in a live region.
3. Timer: `connectedAt` 2:14 ago shows "02:14"; semantics `callTimerSemantics`.
4. Mute tap: `FakeCallService.setMuted(true)`; button turns red with `callMuted`, the strip under the masthead shows, live
   region announces; tapping the strip unmutes. At text scale 2.0 both still fit. Speaker tap: `FakeCallService.setSpeaker(true)`; toggle checked; `FakeCallUiService` proximity lock released.
5. Hang up (call screen and Warning): `hangUp` called once each.
6. ended: `callEnded` + duration and Done; after 3 s, status screen. failed: `callFailed`, body, Done.
7. Back: active → `moveToBack` called, route stays; Warning up → nothing; ended → status screen.
8. medium update: banner over the masthead, call controls still tappable; high: Warning, buzz started, mute and speaker state kept.
9. Event mapping (unit): each `CallEvent` sequence → expected phases; `answer`+`callEnded` without `connected` → failed.
10. Step 4: Phone calls red → calling-account Fix disabled with the hint; both green → Continue enabled; settings shows rows.

## 11. Acceptance (emulator, then one real call when approved)
Gallery shows every phase in ms/en/zh at 1.0/1.5/2.0. With the fake: answer → in-call screen, Warning over it, Hang up ends.
Real call: rings natively over the lock screen; answer with the app killed or in the background opens our screen and
the caller hears her (#316; the trial showed the mic is dead until our screen is in front); screen off at the ear; a `familyAlert` push still reaches the co-pilot path.

Known pitfall: the protected-user build must not register the FCM background handler. FlutterFire then starts a background
engine that re-registers twilio_voice and takes its call events, so the in-call screen never opens (real call, emulator).
