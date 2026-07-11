package com.mozhimuthal.mozhimuthal

data class ChunkFeatures(val vttl_ms: Double, val pfv_std: Double, val cvr_ratio: Double)

class RollingBufferProcessor(
    private val webRTCVad: WebRTCVadBridge,
    private val pyannoteRunner: PyannoteRunner,
    private val featureExtractor: FeatureExtractor
) {
    val CHUNK_SAMPLES = 160_000 // 10 seconds at 16kHz
    
    fun processChunk(chunk: ShortArray, childAgeMonths: Int): ChunkFeatures {
        val vadMask = webRTCVad.process(chunk)
        val segments = pyannoteRunner.diarize(chunk)
        val features = featureExtractor.extract(chunk, segments, childAgeMonths)
        return features
    }
}
