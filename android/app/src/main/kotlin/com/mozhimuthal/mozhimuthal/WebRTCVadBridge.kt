package com.mozhimuthal.mozhimuthal

class WebRTCVadBridge {
    fun process(chunk: ShortArray): BooleanArray {
        // Stub: In a real implementation this would use the JNI WebRTC VAD to mark active frames
        // returning an array of voice activity for each 30ms frame.
        return BooleanArray(chunk.size / 480) { true }
    }
}
