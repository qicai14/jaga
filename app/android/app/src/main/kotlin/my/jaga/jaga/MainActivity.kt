package my.jaga.jaga

import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "jaga/device_setup")
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
