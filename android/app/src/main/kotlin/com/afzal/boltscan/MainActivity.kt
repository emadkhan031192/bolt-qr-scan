package com.afzal.boltscan

import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.afzal.boltscan/beep"
        ).setMethodCallHandler { call, result ->
            if (call.method == "beep") {
                try {
                    val tg = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 80)
                    tg.startTone(ToneGenerator.TONE_PROP_BEEP, 120)
                    Handler(Looper.getMainLooper()).postDelayed({
                        try { tg.release() } catch (_: Exception) { /* ignore */ }
                    }, 200)
                    result.success(null)
                } catch (e: Exception) {
                    // Best-effort beep; never fail the call.
                    result.success(null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
