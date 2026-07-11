package com.mozhimuthal.mozhimuthal

data class SpeakerSegment(val start_ms: Long, val end_ms: Long, val speaker: String)

class PyannoteRunner {
    fun diarize(pcm: ShortArray): List<SpeakerSegment> {
        // Stub: Initialize ONNX session with pyannote model
        // Process the audio and return speaker segments
        return listOf(SpeakerSegment(0, 5000, "ADULT"), SpeakerSegment(5000, 10000, "CHILD"))
    }
}
