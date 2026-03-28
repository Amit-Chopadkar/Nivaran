package com.safeher.safeher

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.*
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.*

/**
 * Full-screen overlay Activity shown on top of the lock screen when SOS is triggered.
 * Displays a 5-second countdown; if not cancelled, it opens the main app to fire the SOS.
 *
 * Uses FLAG_SHOW_WHEN_LOCKED + FLAG_TURN_SCREEN_ON so it appears on the lock screen.
 */
class SOSOverlayActivity : Activity() {

    private val COUNTDOWN_SECONDS = 5
    private var secondsLeft = COUNTDOWN_SECONDS
    private var countdownTimer: CountDownTimer? = null
    private lateinit var tvCountdown: TextView
    private lateinit var tvStatus: TextView
    private lateinit var progressBar: ProgressBar

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Show over the lock screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        buildUI()
        startCountdown()
    }

    private fun buildUI() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#CC0F0F1A"))
            setPadding(60, 80, 60, 80)
        }

        // Shield icon area
        val shieldText = TextView(this).apply {
            text = "🛡️"
            textSize = 72f
            gravity = Gravity.CENTER
        }

        // SOS title
        val tvTitle = TextView(this).apply {
            text = "SOS ALERT"
            textSize = 32f
            setTextColor(Color.parseColor("#FF3B5BDB"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }

        // Countdown circle
        tvCountdown = TextView(this).apply {
            text = "$COUNTDOWN_SECONDS"
            textSize = 80f
            setTextColor(Color.parseColor("#FFEF4444"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }

        tvStatus = TextView(this).apply {
            text = "Sending SOS in $COUNTDOWN_SECONDS seconds..."
            textSize = 16f
            setTextColor(Color.parseColor("#FFCBD5E1"))
            gravity = Gravity.CENTER
        }

        progressBar = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = COUNTDOWN_SECONDS * 10
            progress = COUNTDOWN_SECONDS * 10
            progressDrawable.setTint(Color.parseColor("#FFEF4444"))
            val lp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 12)
            lp.setMargins(0, 32, 0, 32)
            layoutParams = lp
        }

        // Cancel button
        val btnCancel = Button(this).apply {
            text = "CANCEL"
            textSize = 18f
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            setBackgroundColor(Color.parseColor("#FF1E293B"))
            val lp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 140)
            lp.setMargins(0, 24, 0, 0)
            layoutParams = lp
            setOnClickListener { cancelSOS() }
        }

        // Send now button
        val btnNow = Button(this).apply {
            text = "SEND SOS NOW"
            textSize = 18f
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            setBackgroundColor(Color.parseColor("#FFEF4444"))
            val lp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 140)
            lp.setMargins(0, 12, 0, 0)
            layoutParams = lp
            setOnClickListener { fireSOS() }
        }

        val subText = TextView(this).apply {
            text = "Emergency contacts will be notified with your live location"
            textSize = 13f
            setTextColor(Color.parseColor("#FF94A3B8"))
            gravity = Gravity.CENTER
            val lp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT)
            lp.setMargins(0, 40, 0, 0)
            layoutParams = lp
        }

        with(root) {
            addView(shieldText)
            addView(View(context).apply { // spacer
                layoutParams = LinearLayout.LayoutParams(1, 24)
            })
            addView(tvTitle)
            addView(tvCountdown)
            addView(tvStatus)
            addView(progressBar)
            addView(btnNow)
            addView(btnCancel)
            addView(subText)
        }

        setContentView(root)
    }

    private fun startCountdown() {
        countdownTimer = object : CountDownTimer(
            (COUNTDOWN_SECONDS * 1000).toLong(), 100
        ) {
            override fun onTick(millisUntilFinished: Long) {
                val secLeft = ((millisUntilFinished + 999) / 1000).toInt()
                tvCountdown.text = "$secLeft"
                tvStatus.text = "Sending SOS in $secLeft seconds..."
                progressBar.progress = (millisUntilFinished / 100).toInt()
            }

            override fun onFinish() {
                fireSOS()
            }
        }.start()
    }

    private fun fireSOS() {
        countdownTimer?.cancel()
        Log.i("SOSOverlayActivity", "SOS fired!")

        // Launch MainActivity with SOS action
        val intent = Intent(this, MainActivity::class.java).apply {
            action = "com.safeher.safeher.SOS_ACTION"
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        startActivity(intent)
        finish()
    }

    private fun cancelSOS() {
        countdownTimer?.cancel()
        Log.i("SOSOverlayActivity", "SOS cancelled by user")
        finish()
    }

    override fun onBackPressed() {
        cancelSOS()
    }

    override fun onDestroy() {
        countdownTimer?.cancel()
        super.onDestroy()
    }
}
