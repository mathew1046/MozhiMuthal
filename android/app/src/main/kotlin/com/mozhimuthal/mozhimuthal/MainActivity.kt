package com.mozhimuthal.mozhimuthal

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
                // Stub: Read protocol timings, record audio via UnprocessedAudioRecorder,
                // chunk it, process with rollingBufferProcessor.
                // For now, return mock features
                
                val features = mapOf(
                    "vttl_ms" to 1240.0,
                    "pfv_std" to 18.3,
                    "cvr_ratio" to 0.09,
                    "vttl_flagged" to true,
                    "pfv_flagged" to false,
                    "cvr_flagged" to false
                )
                result.success(features)
            } else {
                result.notImplemented()
            }
        }
    }
}
