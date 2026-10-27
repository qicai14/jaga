package my.jaga.jaga

import android.app.NotificationManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Only asked on API 34+ (onboarding checks the SDK first).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "jaga/device_setup")
            .setMethodCallHandler { call, result ->
                if (call.method == "canUseFullScreenIntent") {
                    val manager = getSystemService(NotificationManager::class.java)
                    result.success(manager.canUseFullScreenIntent())
                } else {
                    result.notImplemented()
                }
            }
    }
}
