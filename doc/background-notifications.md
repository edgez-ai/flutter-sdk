# Background notifications and incoming calls

The Android SDK can keep an established BLE session active while the app is
backgrounded or the screen is locked, then display native notifications for
incoming messages and calls. This is different from a Flutter `SnackBar`, which
is visible only while a Flutter screen is in the foreground.

## Runtime flow

1. The host creates one `EdgezMeshSession` and supplies
   `onIncomingMessage` and `onIncomingCall` callbacks.
2. Before connecting, the host calls `requestNotificationPermission()` while
   its activity is visible.
3. Connecting BLE starts `EdgezBleForegroundService`. Its persistent,
   low-priority notification tells the user that EdgeZ is listening.
4. The session decodes and authenticates incoming packets. The host callback
   calls `showIncomingMessageNotification` or
   `showIncomingCallNotification`.
5. Notification links reopen the app on a dedicated voice-call screen. Call
   Answer/Decline links invoke `acceptVoiceCall` or `endVoiceCall` in the
   existing session.

The example implements this flow in
[`example/lib/src/app.dart`](../example/lib/src/app.dart).

## Android manifest

The plugin manifest contributes these permissions and its service declaration
to the host through manifest merging:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />

<application>
    <service
        android:name="ai.edgez.flutter_sdk.EdgezBleForegroundService"
        android:exported="false"
        android:foregroundServiceType="connectedDevice"
        android:stopWithTask="false" />
</application>
```

The existing Bluetooth runtime permission is also a prerequisite for the
`connectedDevice` service. Inspect the merged manifest in the built app if the
host uses manifest replacement rules.

The host activity must accept the notification links. The example declares:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="edgez" android:host="open" />
    <data android:scheme="edgez" android:host="message" />
    <data android:scheme="edgez" android:host="call" />
</intent-filter>
```

Use `launchMode="singleTop"` so notification actions reach the existing
activity and Flutter engine through `onNewIntent`.

## Create the session callbacks

```dart
late final EdgezMeshSession session;

void initializeSession() {
  session = EdgezMeshSession(
    onIncomingMessage: (message, sender) {
      unawaited(
        session.sdk.showIncomingMessageNotification(
          message: message,
          sender: sender,
        ),
      );
    },
    onIncomingCall: (call, caller) {
      unawaited(
        session.sdk.showIncomingCallNotification(
          call: call,
          caller: caller,
        ),
      );
    },
  );
}
```

Request notification permission before BLE connection:

```dart
final allowed = await session.sdk.requestNotificationPermission();
if (!allowed) {
  // Explain that background messages and calls cannot be displayed.
}
await session.connectBle(device.id);
```

Cancel an incoming-call notification when the call is accepted, declined,
ended remotely, or times out:

```dart
await session.sdk.cancelIncomingCallNotification();
```

Canceling the notification deliberately does not remove the activity's
lock-screen visibility: an accepted call must remain usable while the phone is
locked. Clear that presentation only after the call becomes idle:

```dart
await session.sdk.clearCallLockScreenPresentation();
```

## Notification behavior

The native service creates three channels:

| Channel | Importance | Purpose |
| --- | --- | --- |
| BLE connection | Low | Required persistent foreground-service notification. |
| Messages | High | Text and completed voice-message notifications. |
| Incoming calls | High | Public lock-screen call notification with Answer/Decline actions. |

Users can change each channel's sound, vibration, lock-screen visibility, and
importance in Android Settings. Once Android creates a channel, reinstall the
app or clear its data when testing changed channel defaults.

On Android 13 and newer, `POST_NOTIFICATIONS` is a runtime permission. A
foreground service may start without that grant, but message and call
notifications cannot appear normally. The example requests it immediately
before the user-initiated BLE connection.

On Android 14 and newer, check `session.sdk.canUseFullScreenIntent`. If it is
false, Android normally presents the call as an expanded heads-up/lock-screen
notification instead of launching the full-screen activity. Full-screen intent
access is controlled by the user and is intended only for genuine calling or
alarm applications.

## Lock-screen activity

For call notification links, the example activity calls
`setShowWhenLocked(true)` and `setTurnScreenOn(true)`. Answer and Decline are
encoded in `edgez://call` links and routed by `app_links` to the active session.
Flutter presents [`voice_call_screen.dart`](../example/lib/src/voice_call_screen.dart)
for incoming, outgoing, and active calls. It provides Answer, Decline, and End
actions without navigating through the rest of the app. The older conversation
call banner is not rendered. While the app is already foregrounded, the example
uses only this screen and does not post a redundant native call banner. For a
background or locked app, it cancels the native banner as soon as the full-screen
activity is visible.

When an incoming call is answered, the example cancels the ringing notification
but intentionally retains the lock-screen activity flags. It calls
`clearCallLockScreenPresentation` only after the call is declined, ends, or
times out. This lets the active call screen remain visible and usable without
unlocking the phone. On Answer, the same screen transitions to the active phase
and shows elapsed call time until End or a remote hang-up.

The microphone permission must already be granted before an answer can start
live audio. Request it during an understandable foreground user flow rather
than relying on a permission prompt over the lock screen.

## Lifecycle guarantees and limitations

- Supported: switching apps, turning the screen off, and receiving BLE
  notifications while the existing Flutter engine and BLE session remain
  alive.
- Not supported: Android force-stop. No app component can receive BLE events
  after the user force-stops the application.
- Current limitation: GATT is still owned by the Flutter plugin. If Android
  destroys the Flutter engine or process, the service cannot reconstruct the
  encrypted session by itself. Production apps that require recovery after
  process death should persist reconnect metadata and move connection/session
  ownership into a native service or `CompanionDeviceService`.
- OEM battery controls can still interfere. Test locked-screen delivery on
  every supported phone vendor and document any battery-optimization setup
  required by the product.

## Test checklist

1. Fully stop, rebuild, and reinstall the example; native changes do not load
   through hot reload.
2. Grant Bluetooth, notifications, microphone, and full-screen intent access
   where applicable.
3. Connect BLE and confirm the persistent **EdgeZ BLE active** notification.
4. Lock the phone and send a text message from another mesh user.
5. Confirm the message notification opens the correct conversation.
6. Lock the phone and place a voice call from another mesh user.
7. Confirm the dedicated incoming-call screen or expanded call notification
   appears and that Answer/Decline reaches the existing call session.
8. Answer while locked, confirm the active call screen stays visible, then End
   and confirm normal lock-screen behavior returns.
9. Disable notification permission and verify that the foreground fallback is
   shown only while the app is visible.
