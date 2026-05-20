package com.ol1n.mirrorbooth

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(MirrorPlugin())
        flutterEngine.plugins.add(CameraInfoPlugin())
    }
}
