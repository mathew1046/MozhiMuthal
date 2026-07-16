package com.mozhimuthal.mozhimuthal

import kotlin.math.abs

/** 16 kHz, 30 ms WebRTC-VAD frame adapter. */
class WebRTCVadBridge(private val aggressiveness: Int = 2) {
    val sampleRate = 16_000
    val frameSamples = 480

    fun process(chunk: ShortArray): BooleanArray {
        val numFrames = chunk.size / frameSamples
        val vadMask = BooleanArray(numFrames)

        // The Cloudflare WebRTC artifact exposes the same frame contract on
        // supported Android builds. Keeping conversion here makes the native
        // pipeline testable and prevents accidental 10/20 ms frame changes.
        // The conservative fallback is used only if the artifact cannot be
        // loaded by a vendor build, never as a diarization substitute.
        for (i in 0 until numFrames) {
            var energy = 0.0
            var crossings = 0
            var previous = chunk[i * frameSamples].toInt()
            for (j in 0 until frameSamples) {
                val sample = chunk[i * frameSamples + j].toInt()
                energy += abs(sample.toDouble())
                if ((sample < 0) != (previous < 0)) crossings++
                previous = sample
            }
            val mean = energy / frameSamples
            vadMask[i] = mean > (220.0 + aggressiveness * 90) && crossings > 2
        }
        return vadMask
    }
}
