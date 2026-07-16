package com.mozhimuthal.mozhimuthal

import kotlin.math.sqrt

class FeatureExtractor {
    fun extract(chunk: ShortArray, segments: List<SpeakerSegment>, childAgeMonths: Int): ChunkFeatures {
        // Pitch labels are deliberately conservative; uncertain tracks remain
        // UNKNOWN and are excluded from child/adult-derived features.
        val labelled = segments.map { it.copy(speaker = label(chunk, it)) }
        var vttlSum = 0L
        var transitions = 0
        var lastAdultEnd = -1L

        var childDurationMs = 0L

        // Arrays to hold child F0 values
        val childF0s = mutableListOf<Double>()

        for (segment in labelled) {
            if (segment.speaker == "ADULT") {
                lastAdultEnd = segment.end_ms
            } else if (segment.speaker == "CHILD") {
                childDurationMs += (segment.end_ms - segment.start_ms)
                if (lastAdultEnd != -1L && segment.start_ms >= lastAdultEnd) {
                    vttlSum += (segment.start_ms - lastAdultEnd)
                    transitions++
                }

                // Extract F0 for child segment using YIN
                val startSample = (segment.start_ms * 16).toInt()
                val endSample = (segment.end_ms * 16).toInt()
                if (startSample >= 0 && endSample <= chunk.size && endSample > startSample) {
                    val segmentPcm = chunk.copyOfRange(startSample, endSample)
                    val f0 = computeYinPitch(segmentPcm, 16000)
                    if (f0 > 0) childF0s.add(f0)
                }
            }
        }

        val vttl_ms = if (transitions > 0) (vttlSum / transitions.toDouble()) else 0.0
        val cvr_ratio = childDurationMs.toDouble() / (chunk.size / 16.0)

        // Calculate PFV std dev
        var pfv_std = 0.0
        if (childF0s.size > 1) {
            val mean = childF0s.average()
            var sumVariance = 0.0
            for (f0 in childF0s) {
                sumVariance += (f0 - mean) * (f0 - mean)
            }
            pfv_std = sqrt(sumVariance / childF0s.size)
        }

        return ChunkFeatures(vttl_ms, pfv_std, cvr_ratio, 0, childDurationMs,
            chunk.size / 16L, transitions)
    }

    private fun label(chunk: ShortArray, segment: SpeakerSegment): String {
        val start = (segment.start_ms * 16).toInt().coerceAtLeast(0)
        val end = (segment.end_ms * 16).toInt().coerceAtMost(chunk.size)
        if (end - start < 1600) return "UNKNOWN"
        val f0 = computeYinPitch(chunk.copyOfRange(start, end), 16000)
        return when {
            f0 in 260.0..600.0 -> "CHILD"
            f0 in 85.0..220.0 -> "ADULT"
            else -> "UNKNOWN"
        }
    }

    // Simplified YIN algorithm implementation
    private fun computeYinPitch(buffer: ShortArray, sampleRate: Int): Double {
        val tauMax = sampleRate / 50 // Minimum frequency ~50Hz
        val tauMin = sampleRate / 500 // Maximum frequency ~500Hz
        
        if (buffer.size < tauMax) return 0.0

        val yinBuffer = DoubleArray(tauMax)
        
        // Step 1: Difference function
        for (tau in 0 until tauMax) {
            for (i in 0 until buffer.size - tau) {
                val delta = buffer[i].toDouble() - buffer[i + tau].toDouble()
                yinBuffer[tau] += delta * delta
            }
        }

        // Step 2: Cumulative mean normalized difference
        var runningSum = 0.0
        yinBuffer[0] = 1.0
        for (tau in 1 until tauMax) {
            runningSum += yinBuffer[tau]
            if (runningSum > 0) {
                yinBuffer[tau] *= tau / runningSum
            } else {
                yinBuffer[tau] = 1.0
            }
        }

        // Step 3: Absolute threshold
        val threshold = 0.1
        var tauEstimate = -1
        for (tau in tauMin until tauMax) {
            if (yinBuffer[tau] < threshold) {
                // Find local minimum
                var minTau = tau
                while (minTau + 1 < tauMax && yinBuffer[minTau + 1] < yinBuffer[minTau]) {
                    minTau++
                }
                tauEstimate = minTau
                break
            }
        }

        if (tauEstimate == -1) {
            // Fallback: global minimum
            var minVal = Double.MAX_VALUE
            for (tau in tauMin until tauMax) {
                if (yinBuffer[tau] < minVal) {
                    minVal = yinBuffer[tau]
                    tauEstimate = tau
                }
            }
        }

        return if (tauEstimate > 0) sampleRate.toDouble() / tauEstimate else 0.0
    }
}
