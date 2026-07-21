package com.mozhimuthal.mozhimuthal

import kotlin.math.abs
import kotlin.math.ln
import kotlin.math.sqrt

/**
 * Pitch-variability settings for 16 kHz mono child-speech recordings.
 *
 * The semitone reference is a fixed conversion anchor only. It is not a
 * clinical baseline and does not imply that 100 Hz is an expected child F0.
 */
object PfvConfig {
    const val sampleRateHz = 16_000
    const val frameSizeSamples = 512 // 32 ms
    const val hopSizeSamples = 256 // 16 ms / 50% overlap
    const val minimumPitchHz = 50.0
    const val maximumPitchHz = 600.0
    const val yinAbsoluteThreshold = 0.15
    const val minimumConfidence = 0.85
    const val childMinimumPitchHz = 250.0
    const val childMaximumPitchHz = 600.0
    const val medianWindowFrames = 5
    const val minimumValidFrames = 30
    const val semitoneReferenceHz = 100.0
    const val neighborAgreementSemitones = 1.0
    const val maxContourGapMs = 48L
    const val zScoreFlagThreshold = 1.75
}

data class PitchEstimate(val f0Hz: Double, val confidence: Double)

data class PitchFrame(
    val f0Hz: Double,
    val confidence: Double,
    val startMs: Long,
)

data class PfvResult(
    val rawPfvSemitoneSD: Double?,
    val ageZScore: Double?,
    val isFlagged: Boolean,
    val framesUsed: Int,
    val insufficientData: Boolean,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "raw_pfv_semitone_sd" to rawPfvSemitoneSD,
        "age_z_score" to ageZScore,
        "is_flagged" to isFlagged,
        "frames_used" to framesUsed,
        "insufficient_data" to insufficientData,
    )
}

data class PfvAgeReference(
    val label: String,
    val minAgeMonths: Int,
    val maxAgeMonths: Int,
    val meanSemitoneSD: Double,
    val sdSemitoneSD: Double,
)

object PfvAgeReferences {
    /**
     * TODO(clinical-validation): Replace these placeholder values with local,
     * age-banded normative data from a clinically reviewed pilot. They are only
     * integration defaults and must not be treated as validated thresholds.
     *
     * These ranges intentionally mirror the questionnaire's existing bands.
     * At a shared boundary (for example, 15 months), the newer band is used.
     */
    val placeholderReferences = listOf(
        PfvAgeReference("12-15mo", 12, 15, 1.45, 0.45),
        PfvAgeReference("15-18mo", 15, 18, 1.50, 0.45),
        PfvAgeReference("18-21mo", 18, 21, 1.55, 0.45),
        PfvAgeReference("21-24mo", 21, 24, 1.60, 0.45),
        PfvAgeReference("24-30mo", 24, 30, 1.65, 0.50),
        PfvAgeReference("30-36mo", 30, 36, 1.70, 0.50),
    )

    fun forAge(ageMonths: Int): PfvAgeReference? = placeholderReferences
        .lastOrNull { ageMonths in it.minAgeMonths..it.maxAgeMonths }
}

/** Lightweight YIN pitch tracker that exposes both F0 and confidence. */
class YinPitchTracker {
    fun estimate(frame: ShortArray): PitchEstimate? {
        if (frame.size < PfvConfig.frameSizeSamples) return null

        val tauMin = PfvConfig.sampleRateHz / PfvConfig.maximumPitchHz.toInt()
        val tauMax = PfvConfig.sampleRateHz / PfvConfig.minimumPitchHz.toInt()
        val yin = DoubleArray(tauMax + 1)
        for (tau in 1..tauMax) {
            var difference = 0.0
            for (i in 0 until frame.size - tau) {
                val delta = frame[i].toDouble() - frame[i + tau].toDouble()
                difference += delta * delta
            }
            yin[tau] = difference
        }

        var cumulative = 0.0
        yin[0] = 1.0
        for (tau in 1..tauMax) {
            cumulative += yin[tau]
            yin[tau] = if (cumulative > 0.0) yin[tau] * tau / cumulative else 1.0
        }

        var estimate = -1
        for (tau in tauMin..tauMax) {
            if (yin[tau] < PfvConfig.yinAbsoluteThreshold) {
                var localMinimum = tau
                while (localMinimum < tauMax && yin[localMinimum + 1] < yin[localMinimum]) {
                    localMinimum++
                }
                estimate = localMinimum
                break
            }
        }
        if (estimate == -1) {
            estimate = (tauMin..tauMax).minByOrNull { yin[it] } ?: return null
        }

        val confidence = (1.0 - yin[estimate]).coerceIn(0.0, 1.0)
        val f0 = PfvConfig.sampleRateHz.toDouble() / estimate
        return PitchEstimate(f0, confidence)
    }
}

/** Extracts a cleaned child F0 contour and computes age-normed PFV. */
class PfvAnalyzer(private val tracker: YinPitchTracker = YinPitchTracker()) {
    fun estimatePitch(samples: ShortArray): PitchEstimate? = tracker.estimate(samples)

    fun extractFrames(chunk: ShortArray, childSegments: List<SpeakerSegment>): List<PitchFrame> {
        val out = mutableListOf<PitchFrame>()
        for (segment in childSegments) {
            val start = (segment.start_ms * PfvConfig.sampleRateHz / 1000).toInt()
                .coerceAtLeast(0)
            val end = (segment.end_ms * PfvConfig.sampleRateHz / 1000).toInt()
                .coerceAtMost(chunk.size)
            var frameStart = start
            while (frameStart + PfvConfig.frameSizeSamples <= end) {
                val frame = chunk.copyOfRange(frameStart, frameStart + PfvConfig.frameSizeSamples)
                val estimate = tracker.estimate(frame)
                if (estimate != null) {
                    out += PitchFrame(
                        f0Hz = estimate.f0Hz,
                        confidence = estimate.confidence,
                        startMs = frameStart * 1000L / PfvConfig.sampleRateHz,
                    )
                }
                frameStart += PfvConfig.hopSizeSamples
            }
        }
        return out
    }

    fun analyzeFrames(frames: List<PitchFrame>, childAgeMonths: Int): PfvResult {
        val eligible = frames
            .asSequence()
            .filter { it.confidence >= PfvConfig.minimumConfidence }
            .filter {
                it.f0Hz in PfvConfig.childMinimumPitchHz..PfvConfig.childMaximumPitchHz
            }
            .sortedBy { it.startMs }
            .toList()
        val medianFiltered = medianFilter(eligible)
        val cleaned = removeIsolatedOutliers(medianFiltered)
        val semitones = cleaned.map { toSemitone(it.f0Hz) }
        val reference = PfvAgeReferences.forAge(childAgeMonths)
        if (semitones.size < PfvConfig.minimumValidFrames || reference == null) {
            return PfvResult(
                rawPfvSemitoneSD = null,
                ageZScore = null,
                isFlagged = false,
                framesUsed = semitones.size,
                insufficientData = true,
            )
        }

        val mean = semitones.average()
        val variance = semitones.sumOf { value -> (value - mean) * (value - mean) } /
            semitones.size
        val standardDeviation = sqrt(variance)
        val zScore = (standardDeviation - reference.meanSemitoneSD) / reference.sdSemitoneSD
        return PfvResult(
            rawPfvSemitoneSD = standardDeviation,
            ageZScore = zScore,
            isFlagged = abs(zScore) > PfvConfig.zScoreFlagThreshold,
            framesUsed = semitones.size,
            insufficientData = false,
        )
    }

    private fun medianFilter(frames: List<PitchFrame>): List<PitchFrame> {
        if (frames.isEmpty()) return emptyList()
        val radius = PfvConfig.medianWindowFrames / 2
        return frames.indices.map { index ->
            val current = frames[index]
            val start = (index - radius).coerceAtLeast(0)
            val end = (index + radius).coerceAtMost(frames.lastIndex)
            val median = frames.subList(start, end + 1)
                .filter { candidate -> abs(candidate.startMs - current.startMs) <= PfvConfig.maxContourGapMs }
                .map { it.f0Hz }
                .sorted()
                .let { values -> values[values.size / 2] }
            frames[index].copy(f0Hz = median)
        }
    }

    private fun removeIsolatedOutliers(frames: List<PitchFrame>): List<PitchFrame> {
        if (frames.size < 3) return frames
        return frames.filterIndexed { index, frame ->
            if (index == 0 || index == frames.lastIndex) return@filterIndexed true
            val previous = frames[index - 1]
            val next = frames[index + 1]
            if (frame.startMs - previous.startMs > PfvConfig.maxContourGapMs ||
                next.startMs - frame.startMs > PfvConfig.maxContourGapMs) {
                return@filterIndexed true
            }
            val neighborsAgree = abs(toSemitone(previous.f0Hz) - toSemitone(next.f0Hz)) <=
                PfvConfig.neighborAgreementSemitones
            val differsFromPrevious = abs(toSemitone(frame.f0Hz) - toSemitone(previous.f0Hz)) >
                PfvConfig.neighborAgreementSemitones
            val differsFromNext = abs(toSemitone(frame.f0Hz) - toSemitone(next.f0Hz)) >
                PfvConfig.neighborAgreementSemitones
            !(neighborsAgree && differsFromPrevious && differsFromNext)
        }
    }

    private fun toSemitone(f0Hz: Double): Double =
        12.0 * ln(f0Hz / PfvConfig.semitoneReferenceHz) / ln(2.0)
}
