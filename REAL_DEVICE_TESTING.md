# Real Device Screen Time Verification

The simulator cannot validate Apple Screen Time permissions, usage reporting, threshold callbacks, or shields. Use a signed physical iPhone.

## Local Logic Test

Run the pure MVP rules verifier before opening Xcode:

```sh
swift run TimeTankMVPVerifier
```

Expected output:

```text
MVP rules verification passed.
```

## Preflight

1. Confirm the Apple Developer account and provisioning profiles include `com.apple.developer.family-controls` for the app and all extensions.
2. Confirm every target uses the same App Group: `group.com.piperstudio.timetank`.
3. Install a fresh build from Xcode onto the iPhone.
4. Open TimeTank, grant Screen Time access, and select one easy-to-test app.

## One-Minute Threshold Test

1. Go to Settings in TimeTank.
2. Tap `Start 1-Minute Test`.
3. Open the selected app and keep it active for more than one minute.
4. Return to TimeTank > Settings.
5. Confirm diagnostics show:
   - `One-minute device test started.`
   - `Daily budget threshold reached.`
   - `Applied shield...`
6. Reopen the selected app and confirm the TimeTank shield appears.

## Manual Shield Test

1. Go to Settings in TimeTank.
2. Tap `Apply Shield Now`.
3. Open the selected app.
4. Confirm the shield appears immediately.
5. Tap the shield secondary action to bypass.
6. Confirm diagnostics show:
   - `Secondary shield button tapped; bypass started.`
   - `Bypass cooldown monitoring started.`
7. Wait for the bypass window to end and confirm the shield reapplies.

## Usage Report Test

1. Use the selected app for a few minutes.
2. Open TimeTank > Stats.
3. Confirm the Screen Time report shows today's selected-app time, pickups, notifications, first pickup, and longest session.

## If It Fails

- No authorization: check the Family Controls entitlement and provisioning profile.
- Picker works but threshold never fires: check diagnostics for schedule errors and active schedules.
- Threshold fires but no block appears: use `Apply Shield Now`; if manual shield fails, the issue is Managed Settings/provisioning, not Device Activity scheduling.
- Shield appears but bypass/reapply fails: check Shield Action diagnostics and bypass schedule diagnostics.
