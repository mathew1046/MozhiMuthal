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

    fun initialize(modelPath: String) {
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
            // Mock fallback if ONNX model is missing
            Log.w("PyannoteRunner", "Model not initialized. Returning mock segments.")
            return listOf(SpeakerSegment(0, 5000, "ADULT"), SpeakerSegment(5000, 10000, "CHILD"))
        }

        try {
            // Pyannote segmentation takes float32 inputs, [batch, channels, samples]
            val floatArray = FloatArray(pcm.size) { pcm[it] / 32768.0f }
            val shape = longArrayOf(1, 1, pcm.size.toLong())
            val tensor = OnnxTensor.createTensor(env, FloatBuffer.wrap(floatArray), shape)
            
            val result = session?.run(mapOf("input" to tensor))
            val output = result?.get(0)?.value as? Array<Array<FloatArray>> // [batch, frames, speakers]
            
            result?.close()
            tensor.close()

            // In a real implementation, we would threshold the output probabilities
            // to extract segments and use YIN to label CHILD vs ADULT.
            // For now, return mock parsing:
            return listOf(SpeakerSegment(0, 5000, "ADULT"), SpeakerSegment(5000, 10000, "CHILD"))
        } catch (e: Exception) {
            Log.e("PyannoteRunner", "Inference failed", e)
            return emptyList()
        }
    }

    fun close() {
        session?.close()
        env?.close()
    }
}
