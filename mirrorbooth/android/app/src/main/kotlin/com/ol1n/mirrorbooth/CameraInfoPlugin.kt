package com.ol1n.mirrorbooth

import android.annotation.SuppressLint
import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Diagnostic-only channel that reports the device's available camera lenses,
 * their focal lengths, and (where the platform exposes them) zoom ratio ranges
 * and physical sub-camera IDs of a logical multi-camera. Consumed by the debug
 * overlay; the production zoom still flows through the cross-platform `camera`
 * plugin.
 */
class CameraInfoPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "mirrorbooth/camera_info")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getLensInfo" -> {
                try {
                    result.success(buildLensInfo())
                } catch (t: Throwable) {
                    result.error("CAMERA_INFO_FAILED", t.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    @SuppressLint("InlinedApi")
    private fun buildLensInfo(): Map<String, Any> {
        val cm = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val front = mutableListOf<Map<String, Any>>()
        val back = mutableListOf<Map<String, Any>>()

        for (id in cm.cameraIdList) {
            val ch = try {
                cm.getCameraCharacteristics(id)
            } catch (_: Throwable) {
                continue
            }
            val facing = ch.get(CameraCharacteristics.LENS_FACING) ?: continue
            val bucket = when (facing) {
                CameraCharacteristics.LENS_FACING_FRONT -> front
                CameraCharacteristics.LENS_FACING_BACK -> back
                else -> continue
            }

            val focalLengths = ch.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
                ?.map { it.toDouble() } ?: emptyList()
            val maxDigitalZoom = (ch.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM)
                ?: 1.0f).toDouble()

            val info = mutableMapOf<String, Any>(
                "id" to id,
                "focalLengths" to focalLengths,
                "maxDigitalZoom" to maxDigitalZoom,
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val caps = ch.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES) ?: IntArray(0)
                val isLogical = caps.any {
                    it == CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_LOGICAL_MULTI_CAMERA
                }
                info["isLogical"] = isLogical
                if (isLogical) {
                    info["physicalIds"] = ch.physicalCameraIds.toList()
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                ch.get(CameraCharacteristics.CONTROL_ZOOM_RATIO_RANGE)?.let {
                    info["zoomRange"] = listOf(it.lower.toDouble(), it.upper.toDouble())
                }
            }

            bucket.add(info)
        }

        return mapOf(
            "front" to front,
            "back" to back,
        )
    }
}
