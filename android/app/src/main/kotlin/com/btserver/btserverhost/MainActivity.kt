package com.btserver.btserverhost

import android.bluetooth.BluetoothAdapter
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val METHOD = "bt_server"
    private val EVENT = "bt_server_stream"

    private val server = BtServer()
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // NEW: keep references to posted runnables so we can cancel them
    private var startRunnable: Runnable? = null
    private var stopRunnable: Runnable? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT).setStreamHandler(object: EventChannel.StreamHandler {
            override fun onListen(args: Any?, sink: EventChannel.EventSink?) { eventSink = sink }
            override fun onCancel(args: Any?) { eventSink = null }
        })

        server.onReceive = { bytes ->
            runOnUiThread {
                eventSink?.success(bytes)
            }
        }
        server.onLog = { msg ->
            runOnUiThread {
                eventSink?.success(msg.toByteArray(Charsets.UTF_8))
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val secs = (call.argument<Int>("seconds") ?: 10800).coerceIn(5, 10800)
                    val ok = startServerFor(secs)
                    result.success(ok)
                }
                "stop" -> { stopServer(); result.success(true) }
                "send" -> {
                    val data = call.argument<ByteArray>("data") ?: ByteArray(0)
                    result.success(server.send(data))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startServerFor(seconds: Int): Boolean {
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return false

        // Cancel any previous scheduled tasks to avoid cross-fires
        startRunnable?.let { mainHandler.removeCallbacks(it) }
        stopRunnable?.let { mainHandler.removeCallbacks(it) }

        if (!adapter.isEnabled) {
            val enableBt = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            startActivity(enableBt)
        }

        // Request discoverable
        val disc = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE).apply {
            putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300)
        }
        startActivity(disc)

        // Delay so SDP record is published before accept()
        startRunnable = Runnable {
            Log.d("BtServer", "Calling server.start() after SDP delay")
            server.start()
        }
        mainHandler.postDelayed(startRunnable!!, 1800L) // 1.8s; 1500–2000 is fine

        // Auto-stop after N seconds (RE-ENABLE once connect works)
        stopRunnable = Runnable {
            Log.d("BtServer", "Auto stop fired after $seconds s")
            server.stop()
        }
        mainHandler.postDelayed(stopRunnable!!, seconds * 1000L)

        return true
    }

    private fun stopServer() {
        // Cancel pending tasks and stop
        startRunnable?.let { mainHandler.removeCallbacks(it) }
        stopRunnable?.let { mainHandler.removeCallbacks(it) }
        startRunnable = null
        stopRunnable = null
        server.stop()
    }
}
