package com.mozhimuthal.mozhimuthal

import android.Manifest
import android.app.ActivityManager
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import java.io.File
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.Executors
import kotlin.math.sqrt

class MainActivity : FlutterActivity() {
    private val channelName = "com.mozhimuthal/audio_pipeline"
    private lateinit var recorder: UnprocessedAudioRecorder
    private val vad = WebRTCVadBridge(2)
    private val runner = PyannoteRunner()
    private val pfvAnalyzer = PfvAnalyzer()
    private val extractor = FeatureExtractor(pfvAnalyzer)
    private val executor = Executors.newSingleThreadExecutor()
    @Volatile private var processing = false
    private val recordingGeneration = AtomicInteger(0)
    private var modelError: String? = null
    private val aggregate = Aggregate(pfvAnalyzer)
    private var waveformSink: EventChannel.EventSink? = null
    private var microphonePermissionResult: MethodChannel.Result? = null
    private var tts: TextToSpeech? = null
    private var ttsReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        recorder = UnprocessedAudioRecorder(this)
        tts = TextToSpeech(this) { status ->
            ttsReady = status == TextToSpeech.SUCCESS
            if (ttsReady) tts?.language = java.util.Locale("ml", "IN")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "requestPermission" -> {
                            requestMicrophonePermission(result)
                        }
                        "startSession", "startRecording" -> start(result)
                        "stopSession", "stopRecording" -> { stop(); result.success(true) }
                        "replayTemporaryRecording" -> replay(result)
                        "deleteTemporaryRecording" -> { recorder.deleteTemporaryRecording(); result.success(true) }
                        "runPipeline" -> run(call.argument<Int>("child_age_months") ?: 0, result)
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("ERR_PIPELINE", e.message, null)
                }
            }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "$channelName/waveform")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { waveformSink = events }
                override fun onCancel(arguments: Any?) { waveformSink = null }
            })
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mozhimuthal/tts")
            .setMethodCallHandler { call, result ->
                if (call.method == "speakConsent") speakConsent(result) else result.notImplemented()
            }
    }

    private fun requestMicrophonePermission(result: MethodChannel.Result) {
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
            return
        }
        microphonePermissionResult = result
        requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), microphonePermissionRequestCode)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != microphonePermissionRequestCode) return
        val result = microphonePermissionResult ?: return
        microphonePermissionResult = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
        } else {
            result.error("ERR_PERMISSION", "Microphone permission was not granted", null)
        }
    }

    private fun start(result: MethodChannel.Result) {
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            result.error("ERR_PERMISSION", "Microphone permission is required", null); return
        }
        if (processing) { result.error("ERR_ALREADY_RECORDING", "A recording is already in progress", null); return }
        if (!recorder.startRecording()) { result.error("ERR_MIC_UNAVAILABLE", "Could not initialize microphone", null); return }
        aggregate.reset(); modelError = null; processing = true
        val generation = recordingGeneration.incrementAndGet()
        executor.execute {
            val readBuffer = ShortArray(1_600) // 100 ms: responsive waveform updates
            val chunk = ShortArray(160_000)
            var buffered = 0
            while (processing && generation == recordingGeneration.get()) {
                val read = recorder.read(readBuffer, 0, readBuffer.size)
                // `stop()` can release the recorder while read is blocked, and
                // a retry can start a new generation before it returns. Never
                // let an old worker append to or analyse the new recording.
                if (!processing || generation != recordingGeneration.get()) break
                if (read <= 0) continue
                try {
                    recorder.appendToTemporaryRecording(readBuffer, read)
                    val peak = readBuffer.take(read).maxOfOrNull { kotlin.math.abs(it.toInt()) } ?: 0
                    // Speech is usually far below digital full scale. A square-root
                    // curve makes normal conversational levels visible without
                    // changing the recorded samples or analysis features.
                    val visualLevel = kotlin.math.sqrt(peak.toDouble() / Short.MAX_VALUE.toDouble())
                    aggregate.addWaveform(visualLevel.coerceIn(0.0, 1.0))
                    // Platform-channel callbacks must be delivered from the UI thread.
                    runOnUiThread {
                        waveformSink?.success(visualLevel.coerceIn(0.0, 1.0))
                    }
                    if (buffered + read > chunk.size) buffered = 0
                    System.arraycopy(readBuffer, 0, chunk, buffered, read)
                    buffered += read
                } catch (e: Exception) {
                    modelError = e.message ?: "Recording stream failed"
                    continue
                }
                if (buffered < chunk.size) continue
                try {
                    if (modelError == null) {
                        ensureModel()
                        val f = RollingBufferProcessor(vad, runner, extractor)
                            .processChunk(chunk, aggregate.ageMonths)
                        aggregate.add(f)
                    }
                } catch (e: Exception) { modelError = e.message ?: "Inference failed" }
                buffered = 0
            }
        }
        result.success(true)
    }

    private fun stop() {
        processing = false
        recordingGeneration.incrementAndGet()
        recorder.stopRecording()
    }

    private fun replay(result: MethodChannel.Result) {
        if (!recorder.hasTemporaryRecording()) { result.error("ERR_NO_RECORDING", "No recording available to replay", null); return }
        recorder.replayAndDelete { runOnUiThread { result.success(true) } }
    }

    private fun run(ageMonths: Int, result: MethodChannel.Result) {
        val memory = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        val info = ActivityManager.MemoryInfo(); memory.getMemoryInfo(info)
        if (info.availMem < 200L * 1024L * 1024L) { result.error("ERR_LOW_MEMORY", "Insufficient memory", null); return }
        // This task is queued after the recording worker, so the result cannot
        // be read while its final analysis window is still being accumulated.
        executor.execute {
            aggregate.ageMonths = ageMonths
            runOnUiThread {
                result.success(
                    aggregate.payload(
                        recorder.audioSourceUsed,
                        ageMonths,
                        modelError,
                    ),
                )
            }
        }
    }

    private fun speakConsent(result: MethodChannel.Result) {
        val engine = tts
        if (!ttsReady || engine == null) { result.error("ERR_TTS_UNAVAILABLE", "Malayalam text-to-speech is not ready on this device", null); return }
        engine.setOnUtteranceProgressListener(object : android.speech.tts.UtteranceProgressListener() {
            override fun onStart(utteranceId: String) = Unit
            override fun onDone(utteranceId: String) { runOnUiThread { result.success(true) } }
            @Deprecated("Deprecated in Java")
            override fun onError(utteranceId: String) { runOnUiThread { result.error("ERR_TTS", "Consent audio could not be played", null) } }
        })
        val text = "നിങ്ങളുടെ കുട്ടിയുടെ ശബ്ദത്തിലെ ഭാഷാ വികാസ സൂചനകൾ പരിശോധിക്കുന്നതിനാണ് ഈ സ്ക്രീനിംഗ്. ഇത് രോഗനിർണയം അല്ല. ശബ്ദ റെക്കോർഡിംഗ് ഈ ഫോണിൽ മാത്രം വിശകലനം ചെയ്യും; ഓഡിയോ സംഭരിക്കുകയോ പങ്കിടുകയോ ചെയ്യില്ല. നിങ്ങൾക്ക് സമ്മതമാണോ?"
        val status = engine.speak(text, TextToSpeech.QUEUE_FLUSH, Bundle(), "parent-consent")
        if (status == TextToSpeech.ERROR) result.error("ERR_TTS", "Consent audio could not be started", null)
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

    override fun onPause() {
        // The app must not keep the microphone active when the activity is
        // interrupted (for example, by a call or when sent to the background).
        stop()
        super.onPause()
    }

    override fun onDestroy() { stop(); recorder.deleteTemporaryRecording(); executor.shutdownNow(); runner.close(); tts?.shutdown(); super.onDestroy() }

    companion object {
        private const val microphonePermissionRequestCode = 42
    }

    private class Aggregate(private val pfvAnalyzer: PfvAnalyzer) {
        var ageMonths = 0
        var voicedMs = 0L; var childMs = 0L; var recordedMs = 0L; var transitions = 0
        val vttls = mutableListOf<Double>(); val pfvFrames = mutableListOf<PitchFrame>()
        val waveform = mutableListOf<Double>(); val decisionTrace = mutableListOf<Map<String, Any>>()
        fun reset() { voicedMs = 0; childMs = 0; recordedMs = 0; transitions = 0; vttls.clear(); pfvFrames.clear(); waveform.clear(); decisionTrace.clear() }
        fun addWaveform(level: Double) { waveform += level }
        fun add(f: ChunkFeatures) {
            val startMs = recordedMs
            voicedMs += f.voiced_ms; childMs += f.child_voiced_ms; recordedMs += f.recorded_ms; transitions += f.transitions
            if (f.vttl_ms > 0) vttls += f.vttl_ms
            pfvFrames += f.pfv_frames.map { frame ->
                frame.copy(startMs = frame.startMs + startMs)
            }
            decisionTrace += mapOf("start_ms" to startMs, "end_ms" to recordedMs, "vttl_ms" to f.vttl_ms, "pfv_frames" to f.pfv_frames.size, "cvr_ratio" to f.cvr_ratio)
        }
        fun payload(source: String, age: Int, analysisFailure: String?): Map<String, Any?> {
            val reasons = mutableListOf<String>()
            if (analysisFailure != null) {
                reasons += "Audio analysis could not be completed. Please repeat the recording."
            }
            if (voicedMs < 20_000) reasons += "At least 20 seconds of voiced audio is required"
            if (childMs < 5_000) reasons += "At least 5 seconds of confident child speech is required"
            if (transitions < 3) reasons += "At least 3 adult-to-child transitions are required"
            val valid = reasons.isEmpty() && vttls.isNotEmpty()
            val median = vttls.sorted().let { if (it.isEmpty()) 0.0 else it[it.size / 2] }
            val pfv = pfvAnalyzer.analyzeFrames(pfvFrames, age)
            return mapOf("analysis_status" to when {
                analysisFailure != null -> "FAILED"
                valid -> "COMPLETE"
                else -> "INCOMPLETE"
            },
                "quality_reasons" to reasons, "voiced_seconds" to voicedMs / 1000.0,
                "child_voiced_seconds" to childMs / 1000.0, "transition_count" to transitions,
                "vttl_ms" to median,
                // Legacy scalar retained for old clients; it is now semitone SD.
                "pfv_std" to (pfv.rawPfvSemitoneSD ?: 0.0),
                "pfv" to pfv.toMap(),
                "cvr_ratio" to if (recordedMs == 0L) 0.0 else childMs.toDouble() / recordedMs,
                "child_age_months" to age, "audio_source_used" to source,
                "waveform" to waveform, "decision_trace" to decisionTrace,
                "model_version" to "onnx-community/pyannote-segmentation-3.0@pinned", "raw_audio" to false)
        }
    }
}
