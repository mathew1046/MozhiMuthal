package com.mozhimuthal.mozhimuthal

class FeatureExtractor(private val pfvAnalyzer: PfvAnalyzer = PfvAnalyzer()) {
    fun extract(chunk: ShortArray, segments: List<SpeakerSegment>, childAgeMonths: Int): ChunkFeatures {
        // Pitch labels are deliberately conservative; uncertain tracks remain
        // UNKNOWN and are excluded from child/adult-derived features.
        val labelled = segments.map { it.copy(speaker = label(chunk, it)) }
        var vttlSum = 0L
        var transitions = 0
        var lastAdultEnd = -1L

        var childDurationMs = 0L

        val childSegments = mutableListOf<SpeakerSegment>()

        for (segment in labelled) {
            if (segment.speaker == "ADULT") {
                lastAdultEnd = segment.end_ms
            } else if (segment.speaker == "CHILD") {
                childSegments += segment
                childDurationMs += (segment.end_ms - segment.start_ms)
                if (lastAdultEnd != -1L && segment.start_ms >= lastAdultEnd) {
                    vttlSum += (segment.start_ms - lastAdultEnd)
                    transitions++
                }
            }
        }

        val vttl_ms = if (transitions > 0) (vttlSum / transitions.toDouble()) else 0.0
        val cvr_ratio = childDurationMs.toDouble() / (chunk.size / 16.0)

        val pfvFrames = pfvAnalyzer.extractFrames(chunk, childSegments)

        return ChunkFeatures(
            vttl_ms = vttl_ms,
            cvr_ratio = cvr_ratio,
            voiced_ms = 0,
            child_voiced_ms = childDurationMs,
            recorded_ms = chunk.size / 16L,
            transitions = transitions,
            pfv_frames = pfvFrames,
        )
    }

    private fun label(chunk: ShortArray, segment: SpeakerSegment): String {
        val start = (segment.start_ms * 16).toInt().coerceAtLeast(0)
        val end = (segment.end_ms * 16).toInt().coerceAtMost(chunk.size)
        if (end - start < PfvConfig.frameSizeSamples) return "UNKNOWN"
        val labelEnd = (start + PfvConfig.frameSizeSamples).coerceAtMost(end)
        val pitch = pfvAnalyzer.estimatePitch(chunk.copyOfRange(start, labelEnd))
            ?: return "UNKNOWN"
        return when {
            pitch.confidence < PfvConfig.minimumConfidence -> "UNKNOWN"
            pitch.f0Hz in PfvConfig.childMinimumPitchHz..PfvConfig.childMaximumPitchHz -> "CHILD"
            pitch.f0Hz in 85.0..220.0 -> "ADULT"
            else -> "UNKNOWN"
        }
    }
}
