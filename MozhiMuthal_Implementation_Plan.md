# MozhiMuthal (മൊഴിമുതൽ)
## Complete Implementation Plan & Architecture
### Inclucode Finals — 2-Week Build

---

## 1. Project Overview

**Mission:** Replace biased parent self-reporting in Kerala Anganwadi developmental screenings with objective, non-semantic acoustic biomarker analysis — running entirely on-device on a ₹6,000 Android phone.

**Platform:** Flutter (Android-first, Kotlin method channels for native audio HAL access)

**Team:**
- **Dathan** → Flutter UI/UX, consent flow, elicitation screens, result display, referral letter generation, state management, Next.js Web Dashboard
- **Mathew** → Native audio pipeline, ML model integration (ONNX diarization + VAD), biomarker extraction engine, Supabase Architecture & Auth

---

## 2. Full System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP LAYER                         │
│                                                                   │
│  ConsentScreen → ElicitationScreen → ProcessingScreen →          │
│  ResultScreen → ReferralScreen                                    │
│                                                                   │
│  State: Riverpod (providers for session, biomarker, sync state)  │
└────────────────────┬────────────────────────────────────────────┘
                     │ Method Channel
┌────────────────────▼────────────────────────────────────────────┐
│                   KOTLIN NATIVE LAYER (Android)                  │
│                                                                   │
│  AudioSource.UNPROCESSED → PCM Buffer → 10s Rolling Window       │
│  WebRTC VAD → Pyannote ONNX → Feature Extractor (YIN/F0)        │
│                                                                   │
│  Outputs: { vttl_ms, pfv_std, cvr_ratio, child_age_months }     │
└────────────────────┬────────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────────┐
│                     SCORING ENGINE (Dart)                         │
│                                                                   │
│  Threshold Rules → RED / YELLOW / GREEN + Malayalam explanation  │
└────────────────────┬────────────────────────────────────────────┘
                     │ WiFi (async, when available)
┌────────────────────▼────────────────────────────────────────────┐
│          CLOUD LAYER (Supabase + Next.js/Vercel Dashboard)       │
│                                                                   │
│  1D Feature Vector JSON only (no audio, no spectrograms)         │
│  DEIC district-level analytics dashboard                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Repository Structure

```
mozhimuthal/
├── android/
│   └── app/src/main/kotlin/com/mozhimuthal/
│       ├── AudioPipelinePlugin.kt          # Method channel host
│       ├── UnprocessedAudioRecorder.kt     # AudioSource.UNPROCESSED
│       ├── RollingBufferProcessor.kt       # 10s window + OOM guard
│       ├── WebRTCVadBridge.kt              # libwebrtc VAD JNI
│       ├── PyannoteRunner.kt               # ONNX Runtime inference
│       └── FeatureExtractor.kt             # VTTL, PFV, CVR compute
├── assets/
│   ├── models/
│   │   ├── pyannote_seg_3_int8.onnx
│   │   └── webrtc_vad.onnx
│   ├── audio/
│   │   ├── consent_ml.mp3                  # AI4Bharat TTS prompts
│   │   ├── elicit_rattle_ml.mp3
│   │   ├── elicit_toy_ml.mp3
│   │   └── elicit_imitate_ml.mp3
│   └── pictograms/
│       ├── rattle.svg
│       ├── toy_hide.svg
│       └── imitate.svg
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants.dart                  # thresholds, age buckets
│   │   ├── theme.dart                      # Kerala green + accessible palette
│   │   └── routes.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── session_model.dart
│   │   │   ├── biomarker_result.dart
│   │   │   └── child_profile.dart
│   │   ├── repositories/
│   │   │   ├── session_repository.dart     # SQLite local
│   │   │   └── sync_repository.dart        # Supabase upload
│   │   └── local/
│   │       └── database_helper.dart        # sqflite
│   ├── domain/
│   │   ├── scoring_engine.dart             # threshold rules → risk level
│   │   └── referral_generator.dart         # Malayalam referral PDF
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── home/
│   │   │   │   └── home_screen.dart        # Worker dashboard
│   │   │   ├── consent/
│   │   │   │   └── consent_screen.dart
│   │   │   ├── elicitation/
│   │   │   │   ├── elicitation_screen.dart
│   │   │   │   └── protocol_card.dart
│   │   │   ├── processing/
│   │   │   │   └── processing_screen.dart  # animated progress
│   │   │   ├── result/
│   │   │   │   ├── result_screen.dart
│   │   │   │   └── biomarker_chip.dart
│   │   │   └── referral/
│   │   │       └── referral_screen.dart
│   │   └── providers/
│   │       ├── session_provider.dart
│   │       ├── audio_pipeline_provider.dart
│   │       └── sync_provider.dart
│   └── services/
│       ├── audio_pipeline_service.dart     # Dart → Kotlin method channel
│       ├── tts_service.dart                # just_audio player
│       └── whatsapp_service.dart           # url_launcher deep link
├── supabase/
│   └── schema.sql
└── dashboard/                              # Next.js App Router dashboard (separate repo)
    ├── src/
    └── package.json
```

---

## 4. Detailed Screen Flow

```
App Launch
    │
    ▼
HomeScreen
  ─ List of past sessions (SQLite)
  ─ "+ New Screening" button
  ─ Offline/Online badge
    │
    ▼
ChildProfileEntry
  ─ Child name (optional), Age in months (required), Anganwadi ID
  ─ Worker name (pre-saved from settings)
    │
    ▼
ConsentScreen
  ─ Malayalam audio plays automatically
  ─ Worker reads consent phrase aloud (recorded as log, not biometric)
  ─ "Parent has consented" tap → timestamped log entry
    │
    ▼
ElicitationScreen (3 sequential protocols)
  ─ Protocol 1: Rattle (pictogram + Malayalam audio instruction)
      Recording starts. Worker shakes rattle. App waits 60s passively.
  ─ Protocol 2: Toy Hide/Reveal (80s)
  ─ Protocol 3: Imitation "aaa" (60s)
  ─ Progress bar per protocol. "Next" unlocks after minimum duration.
    │
    ▼
ProcessingScreen
  ─ "Analyzing... This takes about 30 seconds"
  ─ Animated waveform (purely visual, no real data shown)
  ─ Kotlin pipeline runs: VAD → Diarize → Feature Extract → Score
    │
    ▼
ResultScreen
  ─ Large colored card: RED / YELLOW / GREEN
  ─ Plain Malayalam explanation (e.g. "ഈ കുട്ടിക്ക് ഉടൻ DEIC സന്ദർശനം ശുപാർശ ചെയ്യുന്നു")
  ─ Three biomarker chips (VTTL / PFV / CVR) with flagged/clear status
  ─ No diagnostic labels. No "autism" or "delay" shown to parent.
  ─ "Generate Referral" button (RED only)
    │
    ▼
ReferralScreen (RED cases only)
  ─ Auto-generated Malayalam referral letter (PDF via pdf package)
  ─ Nearest DEIC address pulled from local JSON by district
  ─ Biomarker JSON summary included
  ─ "Share via WhatsApp" → url_launcher whatsapp:// deep link
```

---

## 5. Native Audio Pipeline (Kotlin) — Mathew's Core Module

### 5.1 AudioSource.UNPROCESSED Setup

```kotlin
// UnprocessedAudioRecorder.kt
val minBuffer = AudioRecord.getMinBufferSize(16000, CHANNEL_IN_MONO, ENCODING_PCM_16BIT)
val audioRecord = AudioRecord.Builder()
    .setAudioSource(MediaRecorder.AudioSource.UNPROCESSED) // bypass OEM AGC
    .setAudioFormat(
        AudioFormat.Builder()
            .setSampleRate(16000)
            .setChannelMask(CHANNEL_IN_MONO)
            .setEncoding(ENCODING_PCM_16BIT)
            .build()
    )
    .setBufferSizeInBytes(minBuffer * 4)
    .build()
```

**Why this matters:** Cheap Realme/Infinix skins apply aggressive AGC that flattens F0 variance. `UNPROCESSED` bypasses all Android HAL post-processing, giving clinically accurate raw PCM.

**Fallback:** If `UNPROCESSED` is unavailable (some AOSP builds), fall back to `VOICE_RECOGNITION` and flag it in session metadata.

### 5.2 Rolling Buffer + OOM Prevention

```kotlin
// RollingBufferProcessor.kt
// 10s window at 16kHz = 160,000 samples = ~320KB per chunk
// Process chunk → extract features → immediately null the buffer reference

val CHUNK_SAMPLES = 160_000  // 10 seconds at 16kHz
val buffer = ShortArray(CHUNK_SAMPLES)

fun processChunk(chunk: ShortArray): ChunkFeatures {
    val vadMask = webRTCVad.process(chunk)           // Step 1: VAD
    val segments = pyannoteRunner.diarize(chunk)      // Step 2: Diarize
    val features = featureExtractor.extract(chunk, segments)  // Step 3: Extract
    // chunk goes out of scope → GC eligible immediately
    return features
}
```

**Memory budget on 2GB device:**
- OS + Flutter runtime: ~600MB
- App baseline: ~80MB
- One audio chunk (10s): 320KB
- ONNX model in memory: ~45MB (INT8 quantized)
- **Total peak: ~730MB** — safe margin on 2GB

### 5.3 WebRTC VAD Integration

Use the `webrtc_vad` pre-built `.aar` (Android archive). Frame size: 30ms frames at 16kHz = 480 samples. Aggressiveness level 2 (balanced for indoor Anganwadi environment with ceiling fans). VAD output: binary mask per 30ms frame — drop frames marked as silence before passing to diarization.

### 5.4 Pyannote Segmentation (INT8 ONNX)

Model: `pyannote/segmentation-3.0` exported to ONNX and quantized to INT8.

```kotlin
// PyannoteRunner.kt
val session = OrtEnvironment.getEnvironment().createSession(
    modelBytes,
    OrtSession.SessionOptions().apply {
        setIntraOpNumThreads(2)  // conservative for thermal throttling
        addConfigEntry("session.use_env_allocators", "1")
    }
)

fun diarize(pcm: ShortArray): List<SpeakerSegment> {
    // Returns: [(start_ms, end_ms, speaker: ADULT|CHILD), ...]
    // Child identified by higher average F0 (>200Hz vs adult <200Hz)
}
```

**Child vs Adult discrimination:** Use F0 as a heuristic classifier post-diarization. Children 12–36 months have mean F0 250–400Hz. Adults 150–200Hz. This avoids needing speaker enrollment.

### 5.5 Feature Extraction

```kotlin
data class SessionFeatures(
    val vttl_ms: Double,      // Vocal Turn-Taking Latency
    val pfv_std: Double,      // Prosodic F0 Variance (std dev)
    val cvr_ratio: Double,    // Child Vocalization Ratio
    val child_age_months: Int,
    val audio_source_used: String  // "UNPROCESSED" or "VOICE_RECOGNITION"
)

// VTTL: For each adult→child transition, measure gap
// Bucket into 500ms bins, take median to reduce diarization edge errors

// PFV: Compute F0 on child segments only using YIN algorithm
// YIN: autocorrelation-based, works on 16kHz mono, no external lib needed
// Only apply for age >= 36 months

// CVR: sum(child_segment_durations) / total_session_duration
```

### 5.6 Method Channel Contract (Dart ↔ Kotlin)

```dart
// audio_pipeline_service.dart
static const _channel = MethodChannel('com.mozhimuthal/audio_pipeline');

Future<Map<String, dynamic>> runPipeline({
  required int childAgeMonths,
  required List<ProtocolTiming> protocols, // start/end timestamps per protocol
}) async {
  final result = await _channel.invokeMethod('runPipeline', {
    'child_age_months': childAgeMonths,
    'protocol_timings': protocols.map((p) => p.toJson()).toList(),
  });
  return Map<String, dynamic>.from(result);
}

// Returns:
// { 'vttl_ms': 1240.0, 'pfv_std': 18.3, 'cvr_ratio': 0.09,
//   'vttl_flagged': true, 'pfv_flagged': false, 'cvr_flagged': false }
```

---

## 6. Scoring Engine (Dart) — Shared Logic

```dart
// domain/scoring_engine.dart

enum RiskLevel { green, yellow, red }

class ScoringEngine {
  static const double VTTL_THRESHOLD_MS = 1000;
  static const double PFV_FLAT_THRESHOLD = 15.0; // std dev below = flat
  static const Map<String, double> CVR_THRESHOLDS = {
    '12_24': 0.08,
    '24_36': 0.12,
    '36_plus': 0.15,
  };

  static BiomarkerResult score(SessionFeatures f) {
    bool vttlFlagged = f.vttl_ms > VTTL_THRESHOLD_MS;

    bool pfvFlagged = false;
    if (f.child_age_months >= 36) {
      pfvFlagged = f.pfv_std < PFV_FLAT_THRESHOLD;
    }

    String ageBucket = _getAgeBucket(f.child_age_months);
    double cvrThreshold = CVR_THRESHOLDS[ageBucket]!;
    bool cvrFlagged = f.cvr_ratio < cvrThreshold;

    int flagCount = [vttlFlagged, pfvFlagged, cvrFlagged]
        .where((f) => f).length;

    RiskLevel level = flagCount >= 2
        ? RiskLevel.red
        : flagCount == 1
            ? RiskLevel.yellow
            : RiskLevel.green;

    return BiomarkerResult(
      riskLevel: level,
      vttlFlagged: vttlFlagged,
      pfvFlagged: pfvFlagged,
      cvrFlagged: cvrFlagged,
      malayalamExplanation: _getExplanation(level),
    );
  }

  static String _getExplanation(RiskLevel level) {
    switch (level) {
      case RiskLevel.red:
        return 'ഈ കുട്ടിക്ക് ഉടൻ DEIC സന്ദർശനം ശുപാർശ ചെയ്യുന്നു. '
               'കൂടുതൽ വിവരങ്ങൾക്ക് ഇന്ന് ഒരു referral letter ലഭ്യമാണ്.';
      case RiskLevel.yellow:
        return 'ഒരു biomarker ആശങ്കാജനകമാണ്. '
               '3 മാസത്തിനുള്ളിൽ വീണ്ടും screening ശുപാർശ ചെയ്യുന്നു.';
      case RiskLevel.green:
        return 'ഈ കുട്ടിയുടെ ഭാഷാ വികാസം പ്രായത്തിന് അനുസൃതമാണ്.';
    }
  }

  static String _getAgeBucket(int months) {
    if (months < 24) return '12_24';
    if (months < 36) return '24_36';
    return '36_plus';
  }
}
```

---

## 7. Data Models

```dart
// data/models/session_model.dart
class SessionModel {
  final String id;                    // UUID
  final String anganwadiId;
  final String workerName;
  final String? childName;            // optional
  final int childAgeMonths;
  final DateTime sessionDate;
  final RiskLevel riskLevel;
  final double vttlMs;
  final double pfvStd;
  final double cvrRatio;
  final bool vttlFlagged;
  final bool pfvFlagged;
  final bool cvrFlagged;
  final String audioSourceUsed;
  final bool syncedToCloud;
  final String districtCode;          // for DEIC lookup
}
```

---

## 8. Local Storage (SQLite)

```sql
-- Sessions table (sqflite)
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  anganwadi_id TEXT NOT NULL,
  worker_name TEXT,
  child_name TEXT,
  child_age_months INTEGER NOT NULL,
  session_date TEXT NOT NULL,
  risk_level TEXT NOT NULL,          -- 'red' | 'yellow' | 'green'
  vttl_ms REAL,
  pfv_std REAL,
  cvr_ratio REAL,
  vttl_flagged INTEGER,              -- 0/1
  pfv_flagged INTEGER,
  cvr_flagged INTEGER,
  audio_source TEXT,
  synced INTEGER DEFAULT 0,
  district_code TEXT
);
```

---

## 9. Cloud Sync & Auth (Supabase)

**Authentication Strategy:**
Anganwadi workers log in using a 4-digit PIN tied to their Anganwadi ID (pre-provisioned in Supabase Auth to avoid SMS costs).

**Offline Sync Strategy:**
A "Sync Unsaved Data" button on the HomeScreen handles batch uploading local SQLite records to Supabase when 4G is available. This is more reliable than background tasks on aggressive battery-saving OEM skins.

```sql
-- supabase/schema.sql
-- Workers table mapped to Auth profiles
CREATE TABLE workers (
  id UUID REFERENCES auth.users PRIMARY KEY,
  anganwadi_id TEXT UNIQUE NOT NULL,
  district_code TEXT NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE screenings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  anganwadi_id TEXT NOT NULL,
  district_code TEXT,
  child_age_months INTEGER,
  risk_level TEXT,
  vttl_ms FLOAT,
  pfv_std FLOAT,
  cvr_ratio FLOAT,
  vttl_flagged BOOLEAN,
  pfv_flagged BOOLEAN,
  cvr_flagged BOOLEAN,
  audio_source TEXT,
  session_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
  -- NO child name, NO audio, NO spectrograms
);

-- RLS: Anganwadi workers can only INSERT, not SELECT others' rows
-- DEIC dashboard uses service_role key with read-all access
```

**Privacy compliance:** The JSON payload is exactly the numeric fields above. No child name is sent unless explicitly enabled. Mathematically impossible to reconstruct speech from F0 values and energy ratios.

---

## 10. Referral Letter Generation

```dart
// domain/referral_generator.dart
// Uses the `pdf` Flutter package

Future<File> generateReferralPDF(SessionModel session) async {
  final deic = DeicDatabase.getByDistrict(session.districtCode);
  final pdf = pw.Document();

  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    build: (context) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('MozhiMuthal — Developmental Screening Referral',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Text('തീയതി: ${DateFormat('dd MMM yyyy').format(session.sessionDate)}'),
        pw.Text('Anganwadi ID: ${session.anganwadiId}'),
        pw.Text('കുട്ടിയുടെ പ്രായം: ${session.childAgeMonths} മാസം'),
        pw.Divider(),
        pw.Text('Acoustic Biomarker Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('VTTL: ${session.vttlMs.toStringAsFixed(0)} ms ${session.vttlFlagged ? "⚠ Flagged" : "✓ Normal"}'),
        pw.Text('CVR Ratio: ${session.cvrRatio.toStringAsFixed(3)} ${session.cvrFlagged ? "⚠ Flagged" : "✓ Normal"}'),
        if (session.pfvFlagged || session.childAgeMonths >= 36)
          pw.Text('PFV Std Dev: ${session.pfvStd.toStringAsFixed(2)} ${session.pfvFlagged ? "⚠ Flagged" : "✓ Normal"}'),
        pw.Divider(),
        pw.Text('ഈ കുട്ടിക്ക് DEIC-ൽ കൂടുതൽ വിലയിരുത്തൽ ആവശ്യമാണ്.'),
        pw.SizedBox(height: 12),
        pw.Text('Nearest DEIC:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(deic.name),
        pw.Text(deic.address),
        pw.Text('Phone: ${deic.phone}'),
        pw.SizedBox(height: 24),
        pw.Text('Generated by MozhiMuthal Acoustic Screening System',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      ],
    ),
  ));

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/referral_${session.id}.pdf');
  await file.writeAsBytes(await pdf.save());
  return file;
}
```

---

## 11. Flutter Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.4

  # Navigation
  go_router: ^13.2.0

  # Local Storage
  sqflite: ^2.3.2
  path_provider: ^2.1.3

  # Cloud
  supabase_flutter: ^2.5.0

  # Audio Playback (TTS prompts)
  just_audio: ^0.9.38

  # PDF Generation
  pdf: ^3.10.8
  printing: ^5.12.0

  # WhatsApp Share
  url_launcher: ^6.2.6

  # Utilities
  uuid: ^4.4.0
  intl: ^0.19.0
  shared_preferences: ^2.2.3

dev_dependencies:
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  flutter_lints: ^4.0.0
```

**Native Android dependencies (build.gradle):**
```gradle
implementation 'com.microsoft.onnxruntime:onnxruntime-android:1.18.0'
// webrtc-vad via pre-compiled .aar in libs/
```

---

## 12. UI/UX Design System

**Color Palette:**
- Primary: `#1B5E20` (Kerala forest green — evokes Anganwadi identity)
- Surface: `#F1F8E9` (light green tint)
- RED risk: `#C62828`
- YELLOW risk: `#F9A825`
- GREEN risk: `#2E7D32`
- Text: `#212121` (high contrast, WCAG AA)

**Typography:**
- English labels: `Noto Sans` (preloaded)
- Malayalam text: `Noto Sans Malayalam` (must be bundled as asset — system font unavailable on many cheap Androids)

**Key UX Principles:**
- Pictograms over text everywhere possible (low-literacy workers)
- All instructions in audio first, text second
- No jargon on screen ("biomarker" never shown to worker)
- Large tap targets (minimum 48×48dp) — workers use this outdoors, one-handed

---

## 13. Detailed Two-Week Sprint Plan

### Week 1 — Foundation, Native ML Audio & App Core

| Day | Dathan (Flutter & Web) | Mathew (Native/ML & Backend) |
|-----|-----------------------|------------------------------|
| **1** | **Scaffolding:** Setup Flutter Riverpod architecture, theme, GoRouter. Create base screen files. | **ML Prep:** Download Pyannote model, quantize to INT8. Setup native Android project struct. |
| **2** | **App Core:** Build SQLite DB helpers, Riverpod State, and UI for `HomeScreen` and `ChildProfileEntry`. | **Native Audio:** Implement `UnprocessedAudioRecorder.kt`. Test AGC bypass on low-end test device. |
| **3** | **Web Scaffold:** Setup Next.js App Router for Dashboard, configure Tailwind, deploy to Vercel. | **Memory Mgt:** Build `RollingBufferProcessor.kt` (10s chunks). Profile memory usage on 2GB RAM device. |
| **4** | **UX Building:** Build `ConsentScreen` (just_audio playback) and basic `ElicitationScreen` cards. | **VAD Integration:** Bridge WebRTC VAD (.aar) via JNI. Test frame-level silence dropping. |
| **5** | **UX Logic:** Elicitation Screen timers, recording state, progression logic, and UI polish. | **Diarization Engine:** Connect Pyannote ONNX session in `PyannoteRunner.kt`. Test speaker segmentation. |
| **6** | **Results UI:** Build `ProcessingScreen` animations and basic `ResultScreen` layout with mock data. | **Feature Extractor:** Implement YIN algorithm for F0, calculate VTTL and CVR ratios natively. |
| **7** | **Integration Pt 1:** Wire the method channel between Flutter UI and Kotlin Native backend. | **Integration Pt 1:** Expose Native API. Write unit tests for pipeline outputs given raw PCM buffers. |

### Week 2 — Cloud Sync, Dashboards, Polish & Demo

| Day | Dathan (Flutter & Web) | Mathew (Native/ML & Backend) |
|-----|-----------------------|------------------------------|
| **8** | **Scoring Engine:** Port ML logic limits into Dart. Wire `ResultScreen` to real Method Channel outputs. | **End-to-End Pipeline:** Test full pipeline (audio -> VAD -> Diarize -> Feature JSON). Fix edge case crashes. |
| **9** | **Web UI:** Build DEIC Dashboard UI in Next.js (Charts, Maps, Data Grids with shadcn/ui). | **Backend Setup:** Configure Supabase Postgres, RLS Policies, Auth (PIN login), and Sync API endpoints. |
| **10** | **App Referrals:** Build `ReferralScreen`, implement PDF Generation (Malayalam fonts), WhatsApp URL Scheme. | **App Cloud:** Implement Flutter Supabase client. Build "Sync Unsaved Data" logic to push local SQLite to Cloud. |
| **11** | **Web Data:** Connect Next.js Dashboard to Supabase. Implement live district-level RED/YELLOW counts. | **Hardware Testing:** Profile battery/CPU consumption. Implement `VOICE_RECOGNITION` fallback if `UNPROCESSED` fails. |
| **12** | **UX Polish:** Fix font loading, text overflows, button sizes. Add edge case UI (e.g. mic permission denied). | **Method Channel Errors:** Define explicit error codes (`ERR_MIC_LOCKED`, `ERR_OOM`). Ensure graceful app failures. |
| **13** | **E2E Testing:** Full field test mimicking Anganwadi worker outdoors. Test Auth login & offline capability. | **App Distribution:** Setup GitHub Actions to build APK automatically. Create download landing page for Judges. |
| **14** | **Demo Prep:** Screen record perfect flows. Build pitch deck focusing on social impact and cost feasibility. | **Final QA:** Final check of Supabase DB connections. Support demo video recording and submit. |

---

## 14. Edge Cases & Mitigations

| Edge Case | Mitigation |
|-----------|-----------|
| Child doesn't vocalize at all | CVR = 0.0 → auto-flagged. App shows "insufficient vocalization" note alongside result |
| `UNPROCESSED` unavailable | Fallback to `VOICE_RECOGNITION`, log `audio_source: fallback`, flag in session metadata for DEIC review |
| OOM crash on 2GB device | Chunk GC after each 10s window. Emergency: reduce to 5s window at runtime if `ActivityManager.getMemoryInfo().availMem < 200MB` |
| Very noisy Anganwadi (ceiling fans, road) | WebRTC VAD level 3 (aggressive) for SNR < threshold detected in first 5s |
| Worker skips protocol early | Minimum 45s enforced per protocol via countdown timer before "Next" button activates |
| No WiFi (rural Anganwadi) | Session stored locally with `synced: 0`. Background sync job retries when connectivity available (WorkManager) |
| Age < 12 months | App blocks screening — show "MozhiMuthal screens children 12–60 months only" |

---

## 15. Demo Script (for Judges)

1. **Open app** → HomeScreen shows 3 past sessions (pre-seeded demo data)
2. **New Screening** → Enter child age: 28 months, Anganwadi ID: KL-IDK-042
3. **Consent** → Malayalam audio plays, tap "Parent has consented"
4. **Protocol 1** → Rattle screen with pictogram. Show the passive recording UI.
5. **Fast-forward** (judge mode: 30s demo audio injected instead of live recording)
6. **Processing** → Animated screen, ~8 seconds on test device
7. **Result: RED** → Large red card. Three biomarkers shown. VTTL and CVR flagged.
8. **Malayalam explanation** → "ഈ കുട്ടിക്ക് ഉടൻ DEIC സന്ദർശനം ശുപാർശ ചെയ്യുന്നു"
9. **Generate Referral** → PDF letter with DEIC address, biomarker data
10. **Share via WhatsApp** → WhatsApp opens with PDF attached
11. **Dashboard** (laptop) → Show district map with RED cluster in Idukki

---

## 16. Judging Criteria Alignment

| Likely Criterion | How MozhiMuthal Hits It |
|-----------------|------------------------|
| **Social Impact** | 35 lakh children screened/year in Kerala, median diagnosis moved from 5 years to <18 months |
| **Technical Innovation** | Non-semantic acoustic biomarkers — language-agnostic, no speech corpus needed |
| **Feasibility** | Runs on ₹6,000 Android. No new hardware. Fits existing Anganwadi worker workflow. |
| **Privacy / Ethics** | Zero audio leaves device. 1D feature vector only. DPDP Act 2023 compliant. |
| **Scalability** | 33,000 Anganwadi centres, zero infrastructure change, offline-first |
| **Completeness** | Full Flutter app + ONNX pipeline + Supabase + DEIC dashboard |

---

## 17. Pre-Hackathon Checklist (Before Day 1)

- [ ] **Mathew:** Download Pyannote segmentation-3.0 weights, convert to ONNX, quantize to INT8 using `onnxruntime.quantization`
- [ ] **Mathew:** Get WebRTC VAD Android .aar (Google WebRTC prebuilt or `ai.picovoice:cobra`)
- [ ] **Dathan:** Generate Malayalam TTS audio for all 7 prompts using AI4Bharat TTS API, save as .mp3
- [ ] **Dathan:** Collect DEIC addresses for all 14 Kerala districts, build `deic_data.json`
- [ ] **Both:** Create GitHub repo, set up branches (`feat/flutter-ui`, `feat/native-pipeline`), agree on PR conventions
- [ ] **Both:** Get 2 test Android devices (≥ one at ₹6,000 tier like Realme C55 or Infinix Hot 40)
- [ ] **Dathan:** Set up Supabase project, run schema.sql, get anon key

---

*Built for Inclucode Finals | Team MozhiMuthal | July 2026*
