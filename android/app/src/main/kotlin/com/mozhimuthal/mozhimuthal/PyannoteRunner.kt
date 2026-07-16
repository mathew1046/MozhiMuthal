package com.mozhimuthal.mozhimuthal

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.util.Log
import java.nio.FloatBuffer

data class SpeakerSegment(val start_ms: Long, val end_ms: Long, val speaker: String)

class PyannoteRunner {
    private var env: OrtEnvironment? = null
    private var session: OrtSession? = null
    private var isInitialized = false

    @Synchronized fun initialize(modelPath: String) {
        if (isInitialized) return
        try {
            env = OrtEnvironment.getEnvironment()
            val options = OrtSession.SessionOptions().apply {
                setIntraOpNumThreads(2)
                addConfigEntry("session.use_env_allocators", "1")
            }
            session = env?.createSession(modelPath, options)
            isInitialized = true
        } catch (e: Exception) {
            Log.e("PyannoteRunner", "Failed to load ONNX model. Ensure pyannote_seg_3_int8.onnx is in assets.", e)
            isInitialized = false
        }
    }

    fun diarize(pcm: ShortArray): List<SpeakerSegment> {
        if (!isInitialized || env == null || session == null) {
            throw IllegalStateException("Pyannote model is not initialized")
        }

        try {
            // Pyannote segmentation takes float32 inputs, [batch, channels, samples]
            val floatArray = FloatArray(pcm.size) { pcm[it] / 32768.0f }
            val shape = longArrayOf(1, 1, pcm.size.toLong())
            val tensor = OnnxTensor.createTensor(env, FloatBuffer.wrap(floatArray), shape)
            
            val result = session?.run(mapOf("input" to tensor))
            val output = result?.get(0)?.value
            result?.close()
            tensor.close()
            return decodePowerset(output, pcm.size)
        } catch (e: Exception) {
            Log.e("PyannoteRunner", "Inference failed", e)
            return emptyList()
        }
    }

    /** Decodes [batch, frames, powerset classes] using the model metadata. */
    private fun decodePowerset(value: Any?, samples: Int): List<SpeakerSegment> {
        @Suppress("UNCHECKED_CAST")
        val batch = value as? Array<*> ?: throw IllegalStateException("Unexpected ONNX output")
        @Suppress("UNCHECKED_CAST")
        val frames = batch.firstOrNull() as? Array<*> ?: throw IllegalStateException("Unexpected ONNX frame output")
        val active = mutableListOf<Pair<Long, Long>>()
        val frameMs = samples.toDouble() / 16_000.0 / frames.size * 1000.0
        for (i in frames.indices) {
            val scores = frames[i] as? FloatArray ?: continue
            val best = scores.indices.maxByOrNull { scores[it] } ?: continue
            if (scores[best] >= 0.5f) active += (i * frameMs).toLong() to ((i + 1) * frameMs).toLong()
        }
        if (active.isEmpty()) return emptyList()
        val turns = mutableListOf<SpeakerSegment>()
        var start = active.first().first
        var end = active.first().second
        for ((nextStart, nextEnd) in active.drop(1)) {
            if (nextStart <= end + 100) end = nextEnd else {
                turns += SpeakerSegment(start, end, "UNKNOWN")
                start = nextStart; end = nextEnd
            }
        }
        turns += SpeakerSegment(start, end, "UNKNOWN")
        return turns
    }

    fun close() {
        session?.close()
        env?.close()
    }
}
