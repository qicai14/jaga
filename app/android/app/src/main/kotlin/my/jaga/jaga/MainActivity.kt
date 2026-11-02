package my.jaga.jaga

import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showForCall(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        showForCall(intent)
    }

    /** Opened for a call: show over the lock screen and wake the screen. Dart clears it when the call ends. */
    private fun showForCall(intent: Intent?) {
        if (intent?.getStringExtra(CallLauncher.ROUTE_EXTRA) == CallLauncher.ROUTE_CALL) setLockScreenAccess(true)
    }

    private fun setLockScreenAccess(on: Boolean) {
        setShowWhenLocked(on)
        setTurnScreenOn(on)
    }

    override fun onResume() {
        super.onResume()
        CallLauncher.cancelNotification(this)
    }

    override fun onStop() {
        // Opened for a call that never reached the in-call screen: don't keep lighting the lock screen.
        if (!CallLauncher.callLive) setLockScreenAccess(false)
        super.onStop()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "jaga/call_ui").setMethodCallHandler { call, result ->
            when (call.method) {
                "setShowWhenLocked" -> {
                    setLockScreenAccess(call.arguments == true)
                    result.success(null)
                }
                "moveToBack" -> {
                    moveTaskToBack(true)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(messenger, "jaga/device_setup")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canUseFullScreenIntent" -> {
                        val manager = getSystemService(NotificationManager::class.java)
                        // The permission only exists from Android 14 (API 34).
                        result.success(
                            Build.VERSION.SDK_INT < 34 || manager.canUseFullScreenIntent()
                        )
                    }
                    "packageName" -> result.success(packageName)
                    else -> result.notImplemented()
                }
            }
    }
}
