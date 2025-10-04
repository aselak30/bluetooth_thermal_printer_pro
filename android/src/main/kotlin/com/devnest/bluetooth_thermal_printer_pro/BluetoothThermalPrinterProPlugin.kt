package com.devnest.bluetooth_thermal_printer_pro

import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.BatteryManager
import android.os.Build
import android.util.Log
import android.widget.Toast
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.OutputStream
import java.util.*
import androidx.annotation.NonNull


private const val TAG = "BTPrinterPro"

class BluetoothThermalPrinterProPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    private var outputStream: OutputStream? = null
    private var mac: String = ""
    private var state: String = "false"

    private val pluginScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "bluetooth_thermal_printer_pro")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        pluginScope.cancel()
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
            "BluetoothStatus" -> {
                val adapter = BluetoothAdapter.getDefaultAdapter()
                result.success(if (adapter?.isEnabled == true) "true" else "false")
            }
            "connectionStatus" -> {
                try {
                    outputStream?.write(" ".toByteArray())
                    result.success(if (outputStream != null) "true" else "false")
                } catch (e: Exception) {
                    outputStream = null
                    showToast("Device was disconnected")
                    result.success("false")
                }
            }
            "connectPrinter" -> {
                val macArg = call.arguments?.toString() ?: ""
                if (macArg.isEmpty()) {
                    result.success("false"); return
                }
                mac = macArg
                pluginScope.launch {
                    val out = withContext(Dispatchers.IO) { connect() }
                    outputStream = out
                    result.success(state)
                }
            }
            "writeBytes" -> {
                val list = call.arguments as? List<*>
                if (list == null) { result.success("false"); return }
                val ints = list.mapNotNull { (it as? Number)?.toInt() }
                val bytes = ByteArray(ints.size + 1)
                bytes[0] = '\n'.code.toByte()
                for (i in ints.indices) bytes[i + 1] = ints[i].toByte()
                try {
                    outputStream?.write(bytes)
                    result.success("true")
                } catch (e: Exception) {
                    outputStream = null
                    showToast("Device was disconnected")
                    result.success("false")
                }
            }
            "printText" -> {
                val arg = call.arguments?.toString() ?: ""
                if (outputStream == null) { result.success("false"); return }
                try {
                    val parts = arg.split("//", limit = 2)
                    val sizeIndex = parts.getOrNull(0)?.toIntOrNull()?.coerceIn(0, 5) ?: 2
                    val text = parts.getOrNull(1) ?: arg
                    outputStream?.run {
                        write(SetBytes.size.getOrNull(sizeIndex) ?: SetBytes.size[2])
                        write(text.toByteArray(Charsets.ISO_8859_1))
                    }
                    result.success("true")
                } catch (e: Exception) {
                    outputStream = null
                    showToast("Device was disconnected")
                    result.success("false")
                }
            }

            "printImage" -> {
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null || outputStream == null) {
                    result.success("false")
                    return
                }
                try {
                    val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                    val command = decodeBitmap(bitmap)
                    outputStream?.write(command)
                    result.success("true")
                } catch (e: Exception) {
                    e.printStackTrace()
                    outputStream = null
                    showToast("Failed to print image")
                    result.success("false")
                }
            }
            
            "bluetothLinked" -> {
                result.success(getLinkedDevices())
            }


            else -> result.notImplemented()
        }
    }

    private fun getLinkedDevices(): List<String> {
        val list = mutableListOf<String>()
        val adapter = BluetoothAdapter.getDefaultAdapter()
        adapter?.bondedDevices?.forEach { device ->
            list.add("${device.name}#${device.address}")
        }
        return list
    }

    private suspend fun connect(): OutputStream? {
        state = "false"
        var out: OutputStream? = null
        try {
            val adapter = BluetoothAdapter.getDefaultAdapter()
            if (adapter != null && adapter.isEnabled) {
                val device = adapter.getRemoteDevice(mac)
                val socket = device.createRfcommSocketToServiceRecord(
                    UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
                )
                adapter.cancelDiscovery()
                socket.connect()
                if (socket.isConnected) {
                    out = socket.outputStream
                    state = "true"
                }
            }
        } catch (e: Exception) {
            Log.d(TAG, "connect error: ${e.message}")
            out?.close()
            state = "false"
        }
        return out
    }

    private fun showToast(msg: String) {
        Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
    }

    object SetBytes {
        val size = arrayOf(
            byteArrayOf(0x1d, 0x21, 0x00),
            byteArrayOf(0x1b, 0x4d, 0x01),
            byteArrayOf(0x1b, 0x4d, 0x00),
            byteArrayOf(0x1d, 0x21, 0x11),
            byteArrayOf(0x1d, 0x21, 0x22),
            byteArrayOf(0x1d, 0x21, 0x33)
        )
    }
}




private fun decodeBitmap(bitmap: Bitmap): ByteArray {
    val bmp = bitmap.copy(Bitmap.Config.ARGB_8888, false)
    val width = bmp.width
    val height = bmp.height

    val bytes = ArrayList<Byte>()

    val widthBytes = (width + 7) / 8
    val command = byteArrayOf(0x1B, 0x2A, 33, (widthBytes % 256).toByte(), (widthBytes / 256).toByte())

    for (y in 0 until height) {
        bytes.addAll(command.toList())
        for (x in 0 until widthBytes * 8) {
            var b = 0
            for (bit in 0..7) {
                val pixelX = x + bit
                if (pixelX < width) {
                    val pixel = bmp.getPixel(pixelX, y)
                    val red = (pixel shr 16) and 0xff
                    val green = (pixel shr 8) and 0xff
                    val blue = pixel and 0xff
                    val gray = (red + green + blue) / 3
                    if (gray < 128) {
                        b = b or (1 shl (7 - bit))
                    }
                }
            }
            bytes.add(b.toByte())
        }
        bytes.add(10) // new line
    }

    return bytes.toByteArray()
}

