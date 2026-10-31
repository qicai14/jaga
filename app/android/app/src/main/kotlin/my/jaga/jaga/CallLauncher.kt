package my.jaga.jaga

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.graphics.PixelFormat
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.View
import android.view.WindowManager

/** Brings the in-call screen forward: a direct start first, plus a full-screen notification for the lock screen. */
object CallLauncher {
    const val ROUTE_EXTRA = "jaga.route"
    const val ROUTE_CALL = "call"
    const val CHANNEL = "jaga_call"
    const val NOTIFICATION_ID = 7201
    private const val TAG = "JagaCallLauncher"

    /** Set by [MainActivity]; read only to log whether Android let the direct start through. */
    @Volatile
    var activityResumed = false

    fun bringForward(context: Context) {
        val open = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            .putExtra(ROUTE_EXTRA, ROUTE_CALL)
        // Android allows a background start while the app has an overlay window on screen.
        val overlay = showOverlay(context)
        try {
            context.startActivity(open)
        } catch (e: RuntimeException) {
            Log.w(TAG, "direct startActivity threw: $e")
        }
        postFullScreen(context, open)
        // startActivity never throws when Android blocks a background start, so look again shortly.
        Handler(Looper.getMainLooper()).postDelayed({
            overlay?.let { context.getSystemService(WindowManager::class.java).removeView(it) }
            Log.i(
                TAG,
                (if (activityResumed) "BAL direct start ALLOWED: activity is in front"
                else "BAL direct start DENIED: activity not in front after 1.5 s") +
                    " (overlay permission: ${overlay != null})",
            )
        }, 1500)
    }

    /** A 1 px invisible window, only if the user allowed "Display over other apps". */
    private fun showOverlay(context: Context): View? {
        if (!Settings.canDrawOverlays(context)) return null
        val view = View(context)
        val params = WindowManager.LayoutParams(
            1, 1,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT,
        )
        return try {
            context.getSystemService(WindowManager::class.java).addView(view, params)
            view
        } catch (e: RuntimeException) {
            Log.w(TAG, "overlay window failed: $e")
            null
        }
    }

    private fun postFullScreen(context: Context, open: Intent) {
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, context.getString(R.string.call_notification_channel), NotificationManager.IMPORTANCE_HIGH),
        )
        val pending = PendingIntent.getActivity(
            context, 0, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        manager.notify(
            NOTIFICATION_ID,
            Notification.Builder(context, CHANNEL)
                .setSmallIcon(context.applicationInfo.icon)
                .setContentTitle(context.getString(R.string.call_notification_title))
                .setContentText(context.getString(R.string.call_notification_open))
                .setCategory(Notification.CATEGORY_CALL)
                .setOngoing(true)
                .setContentIntent(pending)
                .setFullScreenIntent(pending, true)
                .build(),
        )
    }

    fun cancelNotification(context: Context) =
        context.getSystemService(NotificationManager::class.java).cancel(NOTIFICATION_ID)
}
