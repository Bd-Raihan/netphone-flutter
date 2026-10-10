package com.netphoneapp.call

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val CHANNEL =
            "com.netphoneapp.call/call_service"
    }

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "startCallService" -> {
                    startCallService()
                    result.success(true)
                }

                "stopCallService" -> {
                    stopCallService()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun startCallService() {
        val intent =
            Intent(this, CallForegroundService::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopCallService() {
        val intent =
            Intent(this, CallForegroundService::class.java)

        stopService(intent)
    }
}