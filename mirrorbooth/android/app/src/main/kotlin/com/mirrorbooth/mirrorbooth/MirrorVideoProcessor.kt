package com.mirrorbooth.mirrorbooth

import java.util.concurrent.atomic.AtomicBoolean

/**
 * Stores mirror state for the MethodChannel bridge.
 * Actual WebRTC frame processing is added when integrating flutter_webrtc
 * natively (Phase 2 of FaceTimeMirrorBooth) — requires linking against
 * libwebrtc.aar from the flutter_webrtc plugin.
 */
class MirrorVideoProcessor {
    val enabled = AtomicBoolean(false)
    val mirrorLeft = AtomicBoolean(true)
}
