# 0009: The server issues the protected user's app a Voice access token, behind a secret that ships in the APK

**Decision:** `POST /voice-token` returns the `voice-token` contract: `{token, expiresAt}`, nothing else. This amends ADR
0008's statement that the protected user's app holds no token (below).

**The route.** No request body and no query string. The identity comes only from `JAGA_APP_CLIENT_IDENTITY`, never from the request.

- 200: the `voice-token` body, with `Cache-Control: no-store`.
- 404: `Authorization: Bearer <JAGA_APP_TOKEN>` is missing or wrong, or `JAGA_APP_TOKEN` is unset. Compared in constant time,
  the same check and the same bare 404 as `JAGA_COPILOT_TOKEN` (ADR 0008). It runs first, so only a holder of the secret ever sees a 503.
- 503: required config is missing, with the detail `<NAME> is not set`, matching `/twilio/voice`. Required:
  `JAGA_APP_CLIENT_IDENTITY`, `TWILIO_ACCOUNT_SID`, `TWILIO_API_KEY_SID`, `TWILIO_API_KEY_SECRET`, `TWILIO_PUSH_CREDENTIAL_SID`.

**The token.** A JWT signed locally with PyJWT (a direct dependency); no network call. HS256 with `TWILIO_API_KEY_SECRET`,
header `cty: twilio-fpa;v=1`. Claims: `iss` the API key SID, `sub` the account SID, `jti` `<keySid>-<epoch>`, `exp`,
`grants.identity`, `grants.voice.incoming.allow: true`, `grants.voice.push_credential_sid`. This shape was read from
twilio-python's source (`twilio/jwt/access_token`). Lifetime is 1 hour. `expiresAt` is the same instant as `exp`. There is
no outgoing grant, so a leaked token cannot place calls, and this route does not read `TWILIO_TWIML_APP_SID`.

**The app.** It treats the token as opaque and calls `twilio_voice`'s `setTokens(accessToken:, deviceToken:)` with its FCM
token as `deviceToken`. It fetches a new token before `expiresAt` when it is running. Only the protected user's role fetches a
token: a family co-pilot's install of the same app that registered as this identity would ring on the protected user's calls.

**Fake mode and tests.** There is no signer interface, because nothing external varies: one signing path, two sources of credentials.

- `JAGA_USE_FAKES=true`: the route signs the same shape with public placeholders from `jaga/fakes/` (`iss` `SKfake`, `sub`
  `ACfake`, `push_credential_sid` `CRfake`, and a fixed signing key). It reads no Twilio variable, even if one is set, so it
  runs with no Twilio keys and a real secret never signs a fake token. Twilio rejects this token, which is the point: the
  app's fake path works and real registration can't succeed by accident. `JAGA_APP_TOKEN` and `JAGA_APP_CLIENT_IDENTITY` are Jaga's
  own config, not Twilio keys, so the 404 and that 503 behave the same in this mode.
- Tests need no real keys: they set test values in the environment, run the real signing path and decode the result with PyJWT.

**Logging.** The token, `JAGA_APP_TOKEN` and `TWILIO_API_KEY_SECRET` never appear in logs or error details, on the server
or in the app. A 503 names the variable, never a value, and a failure is logged by exception type only.

**Amends ADR 0008.** The protected user's app now holds a token: `JAGA_APP_TOKEN`, and the Voice access tokens it fetches.
ADR 0008's keep-out still holds, because the app does not hold `JAGA_COPILOT_TOKEN` and `/timelines` still answers it 404. The
two must be different values. No pointer is added to 0008, since this repo's ADRs don't carry them.

**Shortcut, and its limit.** `JAGA_APP_TOKEN` stands in for registration that doesn't exist yet. The secret ships in the
APK, so whoever extracts it can get tokens for this identity, register their own device as it and take the protected
user's forwarded calls. They still cannot place calls. Changing the secret needs a new APK. `build-apk.yml` uploads its APK
as an artifact of a public repo, so the real secret must not go into that build. Upgrade when real registration exists (setup, #12/#19).

**Unverified, and the real-call boxes on #12 must check both:**

- Whether Twilio keeps delivering incoming calls after the 1 hour token expires. From memory it does, because the
  registration binding outlives the token. This decides whether a phone left idle for hours still rings.
- Whether registering works with no outgoing grant.

If either fails, the fix is a config-level change (lifetime, grants), recorded by amending this ADR.

**Lanes that must update:**

- Lane A: the route and its tests; `JAGA_APP_TOKEN` in `.env.example`; in `render.yaml`, `JAGA_APP_TOKEN`,
  `TWILIO_ACCOUNT_SID`, `TWILIO_API_KEY_SID`, `TWILIO_API_KEY_SECRET` and `TWILIO_PUSH_CREDENTIAL_SID`, none of which it lists yet.
- Lane B: the `twilio_voice` registration, with `JAGA_APP_TOKEN` given at build time and never committed.
- Lane D: keep the real secret out of `build-apk.yml`'s artifact, and set the secret on the Render service.

**Why:** the app can't register with Twilio without a Voice access token, and only the server may hold the API key secret.
A shared secret is the least that keeps the route from handing tokens to anyone, and reusing the ADR 0008 check adds no new
pattern. It is a real weakening, which is why the grant is incoming only and the lifetime short: a leak costs this one
identity's incoming calls, and never lets anyone place calls on the Twilio account. POST with `no-store` keeps a credential
out of any cache. Fake mode signs for real so that the shape is exercised with no keys, and its placeholders mean it can't
touch a real secret.
