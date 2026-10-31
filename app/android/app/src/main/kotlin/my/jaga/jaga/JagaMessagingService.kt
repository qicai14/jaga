package my.jaga.jaga

import com.google.firebase.messaging.RemoteMessage
import com.twilio.twilio_voice.fcm.TwilioVoiceFcm
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService

/**
 * The one FCM service (priority 100). Twilio call invites and cancels go to twilio_voice natively,
 * so a call rings with the app killed; everything else (family alerts) falls through to FlutterFire.
 */
class JagaMessagingService : FlutterFirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
        if (TwilioVoiceFcm.handleMessage(this, message.data)) return
        super.onMessageReceived(message)
    }

    override fun onNewToken(token: String) {
        TwilioVoiceFcm.updateToken(this, token)
        super.onNewToken(token)
    }
}
