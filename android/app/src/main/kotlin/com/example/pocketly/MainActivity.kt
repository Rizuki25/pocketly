package com.example.pocketly

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var sensitiveScreen = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCREEN_PRIVACY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "setSensitiveScreen") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            sensitiveScreen = call.argument<Boolean>("sensitive") ?: false
            applySensitiveScreenFlag()
            result.success(null)
        }
    }

    override fun onPause() {
        // Cegah Android membuat snapshot task untuk tampilan recent apps.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        applySensitiveScreenFlag()
    }

    private fun applySensitiveScreenFlag() {
        if (sensitiveScreen) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    companion object {
        private const val SCREEN_PRIVACY_CHANNEL = "com.pocketly/screen_privacy"
    }
}
