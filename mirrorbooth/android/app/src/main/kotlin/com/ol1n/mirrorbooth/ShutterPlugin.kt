package com.ol1n.mirrorbooth

import android.os.SystemClock
import android.view.KeyEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Volume-button shutter. MainActivity forwards key events here; while enabled
 * the volume keys are consumed (no system volume change) and reported to Dart
 * as short or long presses.
 */
class ShutterPlugin :
    FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private companion object {
        /** Hold this long to toggle recording instead of taking a photo. */
        const val LONG_PRESS_MS = 500L
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    @Volatile
    private var enabled = false
    private var pressStart: Long? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "mirrorbooth/shutter")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "mirrorbooth/shutter_events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setEnabled" -> {
                enabled = call.argument<Boolean>("enabled") ?: false
                if (!enabled) pressStart = null
                result.success(null)
            }
            "isSupported" -> result.success(true)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
    }

    /** Returns true when the event was consumed as a shutter press. */
    fun handleKeyEvent(event: KeyEvent): Boolean {
        if (!enabled) return false
        if (event.keyCode != KeyEvent.KEYCODE_VOLUME_UP &&
            event.keyCode != KeyEvent.KEYCODE_VOLUME_DOWN
        ) {
            return false
        }
        when (event.action) {
            KeyEvent.ACTION_DOWN -> if (event.repeatCount == 0) {
                pressStart = SystemClock.uptimeMillis()
            }
            KeyEvent.ACTION_UP -> {
                val start = pressStart
                pressStart = null
                if (start != null) {
                    val held = SystemClock.uptimeMillis() - start
                    eventSink?.success(mapOf("long" to (held >= LONG_PRESS_MS)))
                }
            }
        }
        return true
    }
}
