package com.btserver.btserverhost

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.util.Log
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class BtServer {
    companion object {
        private const val TAG = "BtServer"
        private const val SERVICE_NAME = "MySPPServer"
        private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    }

    private val exec = Executors.newSingleThreadExecutor()
    private var serverSocket: BluetoothServerSocket? = null
    private var clientSocket: BluetoothSocket? = null
    private var out: OutputStream? = null
    private val running = AtomicBoolean(false)
    var onReceive: ((ByteArray) -> Unit)? = null
    var onLog: ((String) -> Unit)? = null

    fun start(): Boolean {
        if (running.get()) return true
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return false
        return try {
            Log.d(TAG, "start() called, creating SECURE server socket")           // <— ADDED
            onLog?.invoke("start() called, creating SECURE server socket")        // <— ADDED

            // SECURE RFCOMM ONLY (Vivo/ColorOS prefer this)
            serverSocket = adapter.listenUsingRfcommWithServiceRecord(SERVICE_NAME, SPP_UUID)
            running.set(true)
            exec.submit {
                try {
                    onLog?.invoke("Waiting for SECURE client...")
                    while (running.get()) {
                        onLog?.invoke("Waiting in accept()...")
                        Log.d(TAG, "Waiting in accept()...")

                        val socket = try {
                            serverSocket?.accept() // blocks
                        } catch (e: Exception) {
                            onLog?.invoke("Accept failed: ${e.message}")          // <— ADDED
                            Log.e(TAG, "Accept failed", e)                        // <— ADDED
                            null
                        } ?: break

                        clientSocket = socket
                        onLog?.invoke("Client connected: ${socket.remoteDevice.address}")
                        Log.d(TAG, "Client connected: ${socket.remoteDevice.address}")  // <— ADDED

                        val input: InputStream = socket.inputStream
                        out = socket.outputStream
                        val buf = ByteArray(1024)
                        while (running.get()) {
                            val n = try {
                                input.read(buf)
                            } catch (e: Exception) {
                                onLog?.invoke("Read failed: ${e.message}")        // <— ADDED
                                Log.e(TAG, "Read failed", e)                      // <— ADDED
                                -1
                            }
                            if (n == -1) break
                            onReceive?.invoke(buf.copyOf(n))
                        }
                        try { socket.close() } catch (_: Exception) {}
                        clientSocket = null
                        out = null
                        onLog?.invoke("Client disconnected")
                        Log.d(TAG, "Client disconnected")                          // <— ADDED
                    }
                } catch (e: Exception) {
                    onLog?.invoke("Server error: ${e.message}")
                    Log.e(TAG, "Server error", e)
                } finally {
                    stop()
                }
            }
            true
        } catch (e: Exception) {
            onLog?.invoke("Start failed: ${e.message}")
            Log.e(TAG, "Start failed", e)
            false
        }
    }

    fun stop() {
        Log.d(TAG, "stop() called")               // <— ADDED
        running.set(false)
        try { serverSocket?.close() } catch (_: Exception) {}
        serverSocket = null
        try { clientSocket?.close() } catch (_: Exception) {}
        clientSocket = null
        try { out?.close() } catch (_: Exception) {}
        out = null
    }

    fun send(data: ByteArray): Boolean {
        return try {
            out?.write(data)
            out?.flush()
            true
        } catch (e: Exception) {
            onLog?.invoke("Send failed: ${e.message}")
            false
        }
    }
}
