package com.ol1n.mirrorbooth

import android.graphics.Bitmap
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetector
import com.google.mlkit.vision.face.FaceDetectorOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer

/**
 * Face detection for face-anchored filters (Google ML Kit, on device; the
 * model comes with Google Play services). `detect` takes a small RGBA frame
 * and returns the face boxes, largest first, as [left, top, width, height]
 * normalized with a top-left origin.
 */
class FacePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var detector: FaceDetector? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "mirrorbooth/face")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        detector?.close()
        detector = null
    }

    private fun detector(): FaceDetector = detector ?: FaceDetection.getClient(
        FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setMinFaceSize(0.15f)
            .build()
    ).also { detector = it }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "detect") {
            result.notImplemented()
            return
        }
        val width = call.argument<Int>("width") ?: 0
        val height = call.argument<Int>("height") ?: 0
        val rgba = call.argument<ByteArray>("rgba")
        if (width <= 0 || height <= 0 || rgba == null || rgba.size < width * height * 4) {
            result.success(emptyList<List<Double>>())
            return
        }
        // ARGB_8888 stores pixels as R, G, B, A bytes, the same order as rawRgba.
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        bitmap.copyPixelsFromBuffer(ByteBuffer.wrap(rgba, 0, width * height * 4))
        detector().process(InputImage.fromBitmap(bitmap, 0))
            .addOnSuccessListener { faces ->
                result.success(
                    faces.map { it.boundingBox }
                        .sortedByDescending { it.width() * it.height() }
                        .map { b ->
                            listOf(
                                b.left.toDouble() / width,
                                b.top.toDouble() / height,
                                b.width().toDouble() / width,
                                b.height().toDouble() / height,
                            )
                        }
                )
            }
            .addOnFailureListener { result.success(emptyList<List<Double>>()) }
            .addOnCompleteListener { bitmap.recycle() }
    }
}
