package com.netphoneapp.call

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioManager
import android.net.wifi.WifiManager
import android.os.PowerManager
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.twilio.voice.Call
import com.twilio.voice.CallException
import com.twilio.voice.ConnectOptions
import com.twilio.voice.Voice
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity : FlutterActivity() {
    private val CHANNEL = "netphone_twilio_voice"

    private var activeCall: Call? = null
    private var audioManager: AudioManager? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        initLocks()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startCall" -> {
                        val accessToken = call.argument<String>("accessToken")
                        val to = call.argument<String>("to")
                        val sessionId = call.argument<String>("sessionId") ?: ""

                        if (accessToken.isNullOrBlank() || to.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "accessToken or to missing", null)
                            return@setMethodCallHandler
                        }
                        startCallService()
                        acquireCallLocks()
                        prepareAudio()
                        startTwilioCall(accessToken, to, sessionId)
                        result.success(true)
                    }

                    "endCall" -> {
                        activeCall?.disconnect()
                        activeCall = null
                        restoreAudio()
                        releaseCallLocks()
                        stopCallService()
                        result.success(true)
                    }

                    "setSpeaker" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        setSpeaker(enabled)
                        result.success(true)
                    }

                    "setMute" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        activeCall?.mute(enabled)
                        audioManager?.isMicrophoneMute = enabled
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun startCallService() {
    val intent = Intent(this, CallForegroundService::class.java)
    ContextCompat.startForegroundService(this, intent)
}

private fun stopCallService() {
    val intent = Intent(this, CallForegroundService::class.java)
    stopService(intent)
}


    private fun initLocks() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "NetPhone:CallWakeLock"
        )
        wakeLock?.setReferenceCounted(false)

        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        wifiLock = wifiManager.createWifiLock(
            WifiManager.WIFI_MODE_FULL_HIGH_PERF,
            "NetPhone:CallWifiLock"
        )
        wifiLock?.setReferenceCounted(false)
    }

    private fun acquireCallLocks() {
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        try {
            if (wakeLock?.isHeld != true) {
                wakeLock?.acquire(2 * 60 * 60 * 1000L)
            }
        } catch (_: Exception) {}

        try {
            if (wifiLock?.isHeld != true) {
                wifiLock?.acquire()
            }
        } catch (_: Exception) {}
    }

    private fun releaseCallLocks() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}

        try {
            if (wifiLock?.isHeld == true) {
                wifiLock?.release()
            }
        } catch (_: Exception) {}
    }

    private fun prepareAudio() {
        audioManager?.mode = AudioManager.MODE_IN_COMMUNICATION
        audioManager?.isSpeakerphoneOn = false
        audioManager?.isMicrophoneMute = false
    }

    private fun restoreAudio() {
        audioManager?.isSpeakerphoneOn = false
        audioManager?.isMicrophoneMute = false
        audioManager?.mode = AudioManager.MODE_NORMAL
    }

    private fun setSpeaker(enabled: Boolean) {
        audioManager?.mode = AudioManager.MODE_IN_COMMUNICATION
        audioManager?.isSpeakerphoneOn = enabled
    }

    private fun startTwilioCall(accessToken: String, to: String, sessionId: String) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                101
            )
            releaseCallLocks()
            return
        }

        val params = HashMap<String, String>()
        params["To"] = to
        params["to"] = to
        params["SessionId"] = sessionId

        val connectOptions = ConnectOptions.Builder(accessToken)
            .params(params)
            .build()

        activeCall = Voice.connect(this, connectOptions, object : Call.Listener {
            override fun onConnectFailure(call: Call, error: CallException) {
                restoreAudio()
                releaseCallLocks()
                println("❌ Twilio connect failed: ${error.message}")
            }

            override fun onRinging(call: Call) {
                println("📞 Twilio ringing")
            }

            override fun onConnected(call: Call) {
                acquireCallLocks()
                prepareAudio()
                println("✅ Twilio connected")
            }

            override fun onReconnecting(call: Call, error: CallException) {
                acquireCallLocks()
                prepareAudio()
                println("🔄 Twilio reconnecting: ${error.message}")
            }

            override fun onReconnected(call: Call) {
                acquireCallLocks()
                prepareAudio()
                println("✅ Twilio reconnected")
            }

            override fun onDisconnected(call: Call, error: CallException?) {
                restoreAudio()
                releaseCallLocks()
                stopCallService()
                println("📴 Twilio disconnected: ${error?.message}")
                activeCall = null
            }
        })
    }

    override fun onDestroy() {
        restoreAudio()
        releaseCallLocks()
        super.onDestroy()
    }
}