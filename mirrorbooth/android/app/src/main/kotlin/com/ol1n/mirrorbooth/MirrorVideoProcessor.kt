package com.ol1n.mirrorbooth

import java.util.concurrent.atomic.AtomicBoolean

class MirrorVideoProcessor {
    val enabled = AtomicBoolean(false)
    val mirrorLeft = AtomicBoolean(true)
}
