package com.joints.steviai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.abs
import kotlin.math.roundToInt
import org.json.JSONArray
import org.json.JSONObject

class StevWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { updateWidget(context, appWidgetManager, it) }
    }

    companion object {
        private const val DAILY_LIMIT_GRAMS = 50.0
        private const val PREFERENCES_NAME = "FlutterSharedPreferences"
        private const val LOG_KEY_PREFIX = "flutter.stev-drink-log-v1"

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, StevWidgetProvider::class.java)
            manager.getAppWidgetIds(component).forEach {
                updateWidget(context, manager, it)
            }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int,
        ) {
            val total = readTodayTotal(context)
            val remaining = DAILY_LIMIT_GRAMS - total
            val primaryText = when {
                remaining > 0 -> "${formatGrams(remaining)} g lagi"
                abs(remaining) < 0.05 -> "Jatah habis"
                else -> "Lewat ${formatGrams(-remaining)} g"
            }
            val secondaryText = "${formatGrams(total)} dari 50 g hari ini"
            val views = RemoteViews(context.packageName, R.layout.stev_home_widget)
            views.setTextViewText(R.id.widget_remaining, primaryText)
            views.setTextViewText(R.id.widget_consumed, secondaryText)

            val scanIntent = Intent(context, MainActivity::class.java).apply {
                action = "com.joints.steviai.OPEN_SCAN"
                putExtra(MainActivity.EXTRA_WIDGET_ROUTE, "/scan")
                flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                widgetId,
                scanIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_scan_button, pendingIntent)
            manager.updateAppWidget(widgetId, views)
        }

        private fun readTodayTotal(context: Context): Double {
            val date = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val preferences = context.getSharedPreferences(
                PREFERENCES_NAME,
                Context.MODE_PRIVATE,
            )
            val encoded = preferences.getString("$LOG_KEY_PREFIX-$date", null)
                ?: return 0.0
            return try {
                val decoded = encoded.trim()
                val entries = if (decoded.startsWith("[")) {
                    JSONArray(decoded)
                } else {
                    JSONObject(decoded).optJSONArray("entries") ?: JSONArray()
                }
                var total = 0.0
                for (index in 0 until entries.length()) {
                    val selection = entries.optJSONObject(index) ?: continue
                    total += selectionGrams(selection)
                }
                total
            } catch (_: Exception) {
                0.0
            }
        }

        private fun selectionGrams(selection: JSONObject): Double {
            val drink = selection.optJSONObject("drink") ?: return 0.0
            val sugarLevel = selection.optString("sugarLevel")
            val levels = drink.optJSONObject("levels")
            if (levels != null && sugarLevel.isNotEmpty()) {
                val levelKey = when (sugarLevel) {
                    "normal" -> "normal"
                    "less" -> "less"
                    "noSugar" -> "noSugar"
                    else -> null
                }
                if (levelKey != null && levels.has(levelKey)) {
                    return levels.optDouble(levelKey, 0.0)
                }
            }
            return drink.optDouble("grams", 0.0)
        }

        private fun formatGrams(value: Double): String {
            val rounded = value.roundToInt()
            return if (abs(value - rounded) < 0.05) {
                rounded.toString()
            } else {
                String.format(Locale.US, "%.1f", value)
            }
        }
    }
}
