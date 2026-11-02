package my.jaga.jaga

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Debug builds only: `adb shell am broadcast -n my.jaga.jaga/.DebugBringForwardReceiver` runs the "call answered" path. */
class DebugBringForwardReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) = CallLauncher.bringForward(context)
}
