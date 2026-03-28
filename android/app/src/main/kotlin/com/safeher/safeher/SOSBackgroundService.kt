package com.safeher.safeher

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import android.content.pm.ServiceInfo
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlin.math.sqrt

class SOSBackgroundService : Service(), SensorEventListener {

    companion object {
        const val TAG = "SOSBackgroundService"
        const val CHANNEL_ID = "sos_foreground_channel"
        const val NOTIF_ID = 9001
        const val POWER_PRESS_THRESHOLD = 2       // 2 rapid screen-off events = SOS
        const val POWER_PRESS_WINDOW_MS = 1500L   // within 1.5s
        const val SHAKE_THRESHOLD = 14f            // m/s² gravity-normalised
        const val SHAKE_COOLDOWN_MS = 3000L        // avoid rapid re-triggers

        var isRunning = false
        var sosCallback: (() -> Unit)? = null      // set by MainActivity
    }

    // Sensors
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null

    // Wake lock
    private var wakeLock: PowerManager.WakeLock? = null

    // Shake state
    private var lastShakeTime = 0L
    private var lastAccel = 0f
    private var currentAccel = 0f
    private var prevAccel = SensorManager.GRAVITY_EARTH

    // Power-button press tracking (screen off/on events)
    private val screenReceiver = SOSBroadcastReceiver()
    private var screenOffTimes = mutableListOf<Long>()

    override fun onCreate() {
        super.onCreate()
        isRunning = true

        createNotificationChannel()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIF_ID, buildNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIF_ID, buildNotification())
        }

        // Acquire partial wake lock — keeps CPU alive to listen to events
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "safeher::SOSWakeLock"
        ).apply { acquire(24 * 60 * 60 * 1000L) } // 24h max

        // Removed accelerometer registration for shake trigger
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager

        // Screen on/off events (proxy for power button)
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
        }
        registerReceiver(screenReceiver, filter)

        // Give the receiver a reference to us so it can call onScreenEvent()
        screenReceiver.service = this

        Log.i(TAG, "SOSBackgroundService started")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY // Restart automatically if killed
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        isRunning = false
        // sensorManager.unregisterListener(this) // Listener not registered anymore
        try { unregisterReceiver(screenReceiver) } catch (_: Exception) {}
        wakeLock?.release()
        super.onDestroy()
        Log.i(TAG, "SOSBackgroundService destroyed — restarting")
        // Schedule restart via alarm
        val restartIntent = Intent(this, SOSBackgroundService::class.java)
        val pi = PendingIntent.getService(
            this, 0, restartIntent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )
        (getSystemService(Context.ALARM_SERVICE) as AlarmManager)
            .set(AlarmManager.ELAPSED_REALTIME_WAKEUP, 2000, pi)
    }

    // ── SHAKE DETECTION (REMOVED) ──────────────────────────────────────────────
    override fun onSensorChanged(event: SensorEvent) {
        // Shake detection removed as per user request
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    // ── POWER BUTTON / SCREEN DETECTION ───────────────────────────────────────
    // Android doesn't expose power button presses directly. We track rapid
    // SCREEN_OFF events as a reliable proxy (each power-press = screen off).
    fun onScreenEvent(action: String) {
        if (action != Intent.ACTION_SCREEN_OFF) return
        val now = System.currentTimeMillis()
        screenOffTimes.add(now)
        // Keep only presses within the window
        screenOffTimes.removeAll { now - it > POWER_PRESS_WINDOW_MS }
        Log.d(TAG, "Screen-off count in window: ${screenOffTimes.size}")
        if (screenOffTimes.size >= POWER_PRESS_THRESHOLD) {
            screenOffTimes.clear()
            Log.i(TAG, "Power button shortcut detected")
            triggerSOSConfirmation("power_button")
        }
    }

    // ── TRIGGER ────────────────────────────────────────────────────────────────
    private fun triggerSOSConfirmation(source: String) {
        Log.i(TAG, "Showing SOS overlay (source=$source)")
        sosCallback?.invoke() // Notify Flutter if app is open

        // Always show the overlay — works even on lock screen
        val intent = Intent(this, SOSOverlayActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or
                     Intent.FLAG_ACTIVITY_SINGLE_TOP or
                     Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("source", source)
        }
        startActivity(intent)
    }

    // ── NOTIFICATION ───────────────────────────────────────────────────────────
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "SafeHer SOS Guardian",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Always-on safety monitoring"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val tapIntent = Intent(this, MainActivity::class.java)
        val pi = PendingIntent.getActivity(
            this, 0, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("SafeHer — Safety Active")
            .setContentText("Press power 2× to send SOS")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setOngoing(true)
            .setContentIntent(pi)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
