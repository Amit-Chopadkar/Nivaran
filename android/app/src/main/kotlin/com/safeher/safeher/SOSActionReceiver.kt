package com.safeher.safeher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Receives the SOS button tap from the persistent notification.
 * Works even when the app is completely closed/killed.
 * Directly launches SOSOverlayActivity without needing Flutter.
 */
class SOSActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        Log.i("SOSActionReceiver", "SOS notification button tapped — source=${intent.action}")

        // Launch the full-screen SOS overlay (shows on lock screen too)
        val overlayIntent = Intent(context, SOSOverlayActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            )
            putExtra("source", "notification_button")
        }
        context.startActivity(overlayIntent)
    }
}
