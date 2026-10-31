package my.jaga.jaga

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log

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
        try {
            context.startActivity(open)
        } catch (e: RuntimeException) {
            Log.w(TAG, "direct startActivity threw: $e")
        }
        postFullScreen(context, open)
        // startActivity never throws when Android blocks a background start, so look again shortly.
        Handler(Looper.getMainLooper()).postDelayed({
            Log.i(
                TAG,
                if (activityResumed) "BAL direct start ALLOWED: activity is in front"
                else "BAL direct start DENIED: activity not in front after 1.5 s",
            )
        }, 1500)
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
