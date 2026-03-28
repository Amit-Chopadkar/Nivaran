package com.safeher.safeher

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.util.Log

/**
 * Implementation of App Widget functionality.
 */
class SOSWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "com.safeher.safeher.WIDGET_SOS_ACTION") {
            Log.i("SOSWidgetProvider", "Widget SOS button tapped!")

            // Launch the SOS Overlay Activity
            val overlayIntent = Intent(context, SOSOverlayActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
                )
                putExtra("source", "home_screen_widget")
            }
            context.startActivity(overlayIntent)
        }
    }

    companion object {
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.sos_widget_layout)

            // Setup click intent for the SOS button inside the widget
            val intent = Intent(context, SOSWidgetProvider::class.java).apply {
                action = "com.safeher.safeher.WIDGET_SOS_ACTION"
            }
            // Use FLAG_UPDATE_CURRENT and FLAG_IMMUTABLE
            val pendingIntent = PendingIntent.getBroadcast(
                context, 
                appWidgetId, 
                intent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.widget_sos_button, pendingIntent)
            // No separate icon listener needed now that the button is the whole widget

            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
