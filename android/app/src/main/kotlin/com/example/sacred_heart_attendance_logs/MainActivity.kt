package com.example.sacred_heart_attendance_logs

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "nfc_settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNFCSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NFC_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        // Fallback to general wireless settings
                        try {
                            val intent = Intent(Settings.ACTION_WIRELESS_SETTINGS)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", "Could not open NFC settings", null)
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
