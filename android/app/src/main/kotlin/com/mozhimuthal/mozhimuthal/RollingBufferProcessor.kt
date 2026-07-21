package com.mozhimuthal.mozhimuthal

data class ChunkFeatures(
    val vttl_ms: Double, val cvr_ratio: Double,
    val voiced_ms: Long, val child_voiced_ms: Long, val recorded_ms: Long, val transitions: Int,
    val pfv_frames: List<PitchFrame> = emptyList(),
    val inference_failed: Boolean = false
)

class RollingBufferProcessor(
    private val webRTCVad: WebRTCVadBridge,
    private val pyannoteRunner: PyannoteRunner,
    private val featureExtractor: FeatureExtractor
) {
    val CHUNK_SAMPLES = 160_000 // 10 seconds at 16kHz
    
    fun processChunk(chunk: ShortArray, childAgeMonths: Int): ChunkFeatures {
        val vadMask = webRTCVad.process(chunk)
        val voicedMs = vadMask.count { it } * 30L
        val segments = pyannoteRunner.diarize(chunk)
        val features = featureExtractor.extract(chunk, segments, childAgeMonths)
        return features.copy(voiced_ms = voicedMs)
    }
}
