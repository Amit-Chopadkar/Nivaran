package com.safeher.safeher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Receives system-wide broadcasts:
 *  - SCREEN_ON / SCREEN_OFF  → proxy for power button presses
 *  - BOOT_COMPLETED          → auto-start SOSBackgroundService after reboot
 */
class SOSBroadcastReceiver : BroadcastReceiver() {

    // Back-reference to the service so we can call onScreenEvent()
    var service: SOSBackgroundService? = null

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_SCREEN_OFF,
            Intent.ACTION_SCREEN_ON -> {
                service?.onScreenEvent(intent.action!!)
            }

            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON" -> {
                Log.i("SOSBroadcastReceiver", "Boot completed — starting SOSBackgroundService")
                val svcIntent = Intent(context, SOSBackgroundService::class.java)
                context.startForegroundService(svcIntent)
            }
        }
    }
}
