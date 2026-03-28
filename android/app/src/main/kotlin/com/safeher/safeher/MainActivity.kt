package com.safeher.safeher

import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    companion object {
        const val SOS_CHANNEL = "com.safeher.safeher/sos_background"
    }

    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SOS_CHANNEL
        )

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startSOSService" -> {
                    startSOSService()
                    result.success(true)
                }
                "stopSOSService" -> {
                    stopSOSService()
                    result.success(true)
                }
                "isServiceRunning" -> {
                    result.success(SOSBackgroundService.isRunning)
                }
                else -> result.notImplemented()
            }
        }

        // Register callback — when service triggers SOS while app is open,
        // forward it to Flutter so SafetyService.activateSOS() can fire.
        SOSBackgroundService.sosCallback = {
            runOnUiThread {
                methodChannel?.invokeMethod("onSOSTriggered", null)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Auto-start the background service is disabled on startup to prevent Android 14 FGS crash
        // Service should be started from Flutter after permissions are granted.
        
        // Handle SOS intent fired by SOSOverlayActivity
        handleSOSIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleSOSIntent(intent)
    }

    private fun handleSOSIntent(intent: Intent?) {
        if (intent?.action == "com.safeher.safeher.SOS_ACTION") {
            // Delay slightly to ensure Flutter engine is ready
            flutterEngine?.dartExecutor?.let {
                android.os.Handler(mainLooper).postDelayed({
                    methodChannel?.invokeMethod("onSOSTriggered", null)
                }, 800)
            }
        }
    }

    private fun startSOSService() {
        if (!SOSBackgroundService.isRunning) {
            val intent = Intent(this, SOSBackgroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        }
    }

    private fun stopSOSService() {
        val intent = Intent(this, SOSBackgroundService::class.java)
        stopService(intent)
    }
}
