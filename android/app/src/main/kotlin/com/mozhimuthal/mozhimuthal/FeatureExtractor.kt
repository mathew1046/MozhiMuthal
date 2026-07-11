package com.mozhimuthal.mozhimuthal

class FeatureExtractor {
    fun extract(chunk: ShortArray, segments: List<SpeakerSegment>, childAgeMonths: Int): ChunkFeatures {
        // Stub: Calculate VTTL, PFV (YIN algorithm), and CVR
        return ChunkFeatures(
            vttl_ms = 1200.0,
            pfv_std = 18.5,
            cvr_ratio = 0.15
        )
    }
}
