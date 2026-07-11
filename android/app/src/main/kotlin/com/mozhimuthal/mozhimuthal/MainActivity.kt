package com.mozhimuthal.mozhimuthal

import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mozhimuthal/audio_pipeline"

    private val webRTCVadBridge = WebRTCVadBridge()
    private val pyannoteRunner = PyannoteRunner()
    private val featureExtractor = FeatureExtractor()
    private val rollingBufferProcessor = RollingBufferProcessor(
        webRTCVadBridge,
        pyannoteRunner,
        featureExtractor
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "runPipeline") {
                val childAgeMonths = call.argument<Int>("child_age_months") ?: 0
                
                // Memory check before starting
                val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val memoryInfo = ActivityManager.MemoryInfo()
                activityManager.getMemoryInfo(memoryInfo)
                
                if (memoryInfo.availMem < 200 * 1024 * 1024) { // Less than 200MB
                    result.error("ERR_OOM", "Insufficient memory to run audio pipeline", null)
                    return@setMethodCallHandler
                }

                val audioRecorder = UnprocessedAudioRecorder()
                val started = audioRecorder.startRecording()
                if (!started) {
                    result.error("ERR_MIC_LOCKED", "Could not initialize audio recorder", null)
                    return@setMethodCallHandler
                }

                try {
                    // Stub: Read protocol timings, record audio via UnprocessedAudioRecorder,
                    // chunk it, process with rollingBufferProcessor.
                    // For now, return mock features
                    
                    val features = mapOf(
                        "vttl_ms" to 1240.0,
                        "pfv_std" to 18.3,
                        "cvr_ratio" to 0.09,
                        "vttl_flagged" to true,
                        "pfv_flagged" to false,
                        "cvr_flagged" to false,
                        "audio_source_used" to audioRecorder.audioSourceUsed
                    )
                    result.success(features)
                } catch (e: Exception) {
                    result.error("ERR_PIPELINE_FAILED", e.message, null)
                } finally {
                    audioRecorder.stopRecording()
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
