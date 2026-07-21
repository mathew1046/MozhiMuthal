package com.mozhimuthal.mozhimuthal

import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PfvAnalyzerTest {
    private val analyzer = PfvAnalyzer()

    @Test
    fun `normal variability produces an unflagged semitone PFV`() {
        val result = analyzer.analyzeFrames(frames(blocks = listOf(270.0, 330.0, 270.0, 330.0)), 24)

        assertFalse(result.insufficientData)
        assertFalse(result.isFlagged)
        assertTrue(result.rawPfvSemitoneSD!! > 1.0)
        assertTrue(result.framesUsed >= PfvConfig.minimumValidFrames)
    }

    @Test
    fun `flat contour is flagged on the low side of the two-sided z score`() {
        val result = analyzer.analyzeFrames(frames(blocks = List(4) { 300.0 }), 24)

        assertFalse(result.insufficientData)
        assertTrue(result.isFlagged)
        assertTrue(result.ageZScore!! < -PfvConfig.zScoreFlagThreshold)
    }

    @Test
    fun `erratic contour is flagged on the high side of the two-sided z score`() {
        val result = analyzer.analyzeFrames(frames(blocks = listOf(250.0, 600.0, 250.0, 600.0)), 24)

        assertFalse(result.insufficientData)
        assertTrue(result.isFlagged)
        assertTrue(result.ageZScore!! > PfvConfig.zScoreFlagThreshold)
    }

    @Test
    fun `fewer than thirty valid frames is insufficient data`() {
        val result = analyzer.analyzeFrames(frames(blocks = listOf(280.0, 320.0), framesPerBlock = 14), 24)

        assertTrue(result.insufficientData)
        assertFalse(result.isFlagged)
        assertNull(result.rawPfvSemitoneSD)
    }

    @Test
    fun `confidence filtering can make a contour insufficient`() {
        val mixedConfidence = List(40) { index ->
            PitchFrame(
                f0Hz = if (index % 2 == 0) 280.0 else 320.0,
                confidence = if (index < 5) 0.95 else 0.20,
                startMs = index * 16L,
            )
        }

        val result = analyzer.analyzeFrames(mixedConfidence, 24)

        assertTrue(result.insufficientData)
        assertTrue(result.framesUsed < PfvConfig.minimumValidFrames)
    }

    private fun frames(
        blocks: List<Double>,
        framesPerBlock: Int = 10,
    ): List<PitchFrame> = blocks.flatMapIndexed { blockIndex, f0 ->
        List(framesPerBlock) { frameIndex ->
            PitchFrame(
                f0Hz = f0,
                confidence = 0.95,
                startMs = (blockIndex * framesPerBlock + frameIndex) * 16L,
            )
        }
    }
}
