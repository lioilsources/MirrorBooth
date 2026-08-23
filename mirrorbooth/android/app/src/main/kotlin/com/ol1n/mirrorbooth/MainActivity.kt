package com.ol1n.mirrorbooth

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private val shutterPlugin = ShutterPlugin()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(MirrorPlugin())
        flutterEngine.plugins.add(shutterPlugin)
    }

    // Volume keys reach the activity before the system volume handler, so the
    // shutter can claim them while the preview is on screen.
    override fun dispatchKeyEvent(event: KeyEvent): Boolean =
        shutterPlugin.handleKeyEvent(event) || super.dispatchKeyEvent(event)
}
