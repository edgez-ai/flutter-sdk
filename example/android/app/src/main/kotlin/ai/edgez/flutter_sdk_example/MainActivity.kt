package ai.edgez.flutter_sdk_example

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        configureLockScreen(intent)
    }

    override fun onNewIntent(intent: Intent) {
        configureLockScreen(intent)
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun configureLockScreen(intent: Intent?) {
        val showForIncomingCall = intent?.data?.let { uri ->
            uri.scheme == "edgez" && uri.host == "call"
        } == true
        if (Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(showForIncomingCall)
            setTurnScreenOn(showForIncomingCall)
        } else if (showForIncomingCall) {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        } else {
            @Suppress("DEPRECATION")
            window.clearFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
    }
}
