package my.jaga.jaga

import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.twilio.twilio_voice.types.TVNativeCallActions

/**
 * Process-wide, so it works while Flutter is not running (the plugin's ConnectionService keeps the
 * process alive for the call). When a call is answered from the phone's own call screen, Jaga's
 * activity must come to the front: while it is in the background Android silences the mic.
 */
class JagaApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        LocalBroadcastManager.getInstance(this).registerReceiver(
            object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) = CallLauncher.bringForward(context)
            },
            IntentFilter(TVNativeCallActions.ACTION_ANSWERED),
        )
    }
}
