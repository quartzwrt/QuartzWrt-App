package com.quartzwrt.quartzwrt_app

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // mDNS 局域网发现：Android 的 Wi-Fi 栈默认过滤组播包，必须持有
        // WifiManager.MulticastLock 才能收到 224.0.0.251:5353。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "quartz/multicast")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "acquire" -> {
                        try {
                            val lock = multicastLock ?: run {
                                val wifi = applicationContext
                                    .getSystemService(Context.WIFI_SERVICE) as WifiManager
                                wifi.createMulticastLock("quartz-mdns").apply {
                                    setReferenceCounted(false)
                                }.also { multicastLock = it }
                            }
                            if (!lock.isHeld) lock.acquire()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("multicast_lock_failed", e.message, null)
                        }
                    }

                    "release" -> {
                        try {
                            multicastLock?.let { if (it.isHeld) it.release() }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("multicast_unlock_failed", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        try {
            multicastLock?.let { if (it.isHeld) it.release() }
        } catch (_: Exception) {
            // ignore
        }
        multicastLock = null
        super.onDestroy()
    }
}
