package com.joints.steviai

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var homeWidgetChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        homeWidgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            HOME_WIDGET_CHANNEL,
        )
        homeWidgetChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialRoute" -> result.success(consumeWidgetRoute(intent))
                "updateWidget" -> {
                    StevWidgetProvider.updateAll(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val route = consumeWidgetRoute(intent) ?: return
        if (::homeWidgetChannel.isInitialized) {
            homeWidgetChannel.invokeMethod("openRoute", route)
        }
    }

    private fun consumeWidgetRoute(intent: Intent?): String? {
        val route = intent?.getStringExtra(EXTRA_WIDGET_ROUTE)
        intent?.removeExtra(EXTRA_WIDGET_ROUTE)
        return route
    }

    companion object {
        const val EXTRA_WIDGET_ROUTE = "stev_widget_route"
        private const val HOME_WIDGET_CHANNEL = "com.joints.steviai/home_widget"
    }
}
