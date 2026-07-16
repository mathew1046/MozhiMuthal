package com.mozhimuthal.mozhimuthal

import android.Manifest
import android.app.ActivityManager
import android.content.pm.PackageManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import kotlin.math.sqrt

class MainActivity : FlutterActivity() {
    private val channelName = "com.mozhimuthal/audio_pipeline"
    private lateinit var recorder: UnprocessedAudioRecorder
    private val vad = WebRTCVadBridge(2)
    private val runner = PyannoteRunner()
    private val extractor = FeatureExtractor()
    private val executor = Executors.newSingleThreadExecutor()
    private var processing = false
    private var modelError: String? = null
    private val aggregate = Aggregate()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        recorder = UnprocessedAudioRecorder(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "requestPermission" -> {
                            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 42)
                            result.success(true)
                        }
                        "startSession", "startRecording" -> start(result)
                        "stopSession", "stopRecording" -> { stop(); result.success(true) }
                        "runPipeline" -> run(call.argument<Int>("child_age_months") ?: 0, result)
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("ERR_PIPELINE", e.message, null)
                }
            }
    }

    private fun start(result: MethodChannel.Result) {
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            result.error("ERR_PERMISSION", "Microphone permission is required", null); return
        }
        if (!recorder.startRecording()) { result.error("ERR_MIC_UNAVAILABLE", "Could not initialize microphone", null); return }
        aggregate.reset(); processing = true
        executor.execute {
            val chunk = ShortArray(160_000)
            while (processing) {
                val read = recorder.read(chunk, 0, chunk.size)
                if (read <= 0) continue
                try {
                    if (modelError == null) {
                        ensureModel()
                        val f = RollingBufferProcessor(vad, runner, extractor)
                            .processChunk(chunk.copyOf(read), aggregate.ageMonths)
                        aggregate.add(f)
                    }
                } catch (e: Exception) { modelError = e.message ?: "Inference failed" }
            }
        }
        result.success(true)
    }

    private fun stop() { processing = false; recorder.stopRecording() }

    private fun run(ageMonths: Int, result: MethodChannel.Result) {
        val memory = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        val info = ActivityManager.MemoryInfo(); memory.getMemoryInfo(info)
        if (info.availMem < 200L * 1024L * 1024L) { result.error("ERR_LOW_MEMORY", "Insufficient memory", null); return }
        aggregate.ageMonths = ageMonths
        if (modelError != null) { result.error("ERR_MODEL_LOAD", modelError, null); return }
        result.success(aggregate.payload(recorder.audioSourceUsed, ageMonths))
    }

    private fun ensureModel() {
        if (runnerReady) return
        val source = assets.open("models/pyannote-segmentation-3.0.onnx")
        val target = File(cacheDir, "pyannote-segmentation-3.0.onnx")
        target.outputStream().use { output -> source.use { it.copyTo(output) } }
        runner.initialize(target.absolutePath)
        runnerReady = true
    }
    private var runnerReady = false

    override fun onDestroy() { stop(); executor.shutdownNow(); runner.close(); super.onDestroy() }

    private class Aggregate {
        var ageMonths = 0
        var voicedMs = 0L; var childMs = 0L; var recordedMs = 0L; var transitions = 0
        val vttls = mutableListOf<Double>(); val pfvs = mutableListOf<Double>()
        fun reset() { voicedMs = 0; childMs = 0; recordedMs = 0; transitions = 0; vttls.clear(); pfvs.clear() }
        fun add(f: ChunkFeatures) { voicedMs += f.voiced_ms; childMs += f.child_voiced_ms; recordedMs += f.recorded_ms; transitions += f.transitions; if (f.vttl_ms > 0) vttls += f.vttl_ms; if (f.pfv_std > 0) pfvs += f.pfv_std }
        fun payload(source: String, age: Int): Map<String, Any> {
            val reasons = mutableListOf<String>()
            if (voicedMs < 20_000) reasons += "At least 20 seconds of voiced audio is required"
            if (childMs < 5_000) reasons += "At least 5 seconds of confident child speech is required"
            if (transitions < 3) reasons += "At least 3 adult-to-child transitions are required"
            val valid = reasons.isEmpty() && vttls.isNotEmpty()
            val median = vttls.sorted().let { if (it.isEmpty()) 0.0 else it[it.size / 2] }
            return mapOf("analysis_status" to if (valid) "COMPLETE" else "INCOMPLETE",
                "quality_reasons" to reasons, "voiced_seconds" to voicedMs / 1000.0,
                "child_voiced_seconds" to childMs / 1000.0, "transition_count" to transitions,
                "vttl_ms" to median, "pfv_std" to (pfvs.averageOrZero()),
                "cvr_ratio" to if (recordedMs == 0L) 0.0 else childMs.toDouble() / recordedMs,
                "child_age_months" to age, "audio_source_used" to source,
                "model_version" to "onnx-community/pyannote-segmentation-3.0@pinned", "raw_audio" to false)
        }
        private fun List<Double>.averageOrZero() = if (isEmpty()) 0.0 else average()
    }
}
