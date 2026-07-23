import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/child_profile.dart';
import '../../data/models/biomarker_result.dart';
import '../../data/models/session_model.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/my_child_engine.dart';
import 'package:uuid/uuid.dart';

/// Current screening session state.
class SessionState {
  final ChildProfile? childProfile;
  final BiomarkerResult? result;
  final double vttlMs;
  final double pfvStd;
  final double cvrRatio;
  final String audioSource;
  final String analysisStatus;
  final List<String> qualityReasons;
  final int transitionCount;
  final double voicedSeconds;
  final double childVoicedSeconds;
  final bool isComplete;
  final SessionModel? savedSession;
  final List<double> waveform;
  final List<Map<String, dynamic>> decisionTrace;
  final Map<String, MyChildAnswer> questionnaireAnswers;
  final MyChildState? questionnaireState;
  final MyChildEvaluation? questionnaireEvaluation;

  const SessionState({
    this.childProfile,
    this.result,
    this.vttlMs = 0,
    this.pfvStd = 0,
    this.cvrRatio = 0,
    this.audioSource = 'MOCK',
    this.analysisStatus = 'COMPLETE',
    this.qualityReasons = const [],
    this.transitionCount = 0,
    this.voicedSeconds = 0,
    this.childVoicedSeconds = 0,
    this.isComplete = false,
    this.savedSession,
    this.waveform = const [],
    this.decisionTrace = const [],
    this.questionnaireAnswers = const {},
    this.questionnaireState,
    this.questionnaireEvaluation,
  });

  SessionState copyWith({
    ChildProfile? childProfile,
    BiomarkerResult? result,
    double? vttlMs,
    double? pfvStd,
    double? cvrRatio,
    String? audioSource,
    String? analysisStatus,
    List<String>? qualityReasons,
    int? transitionCount,
    double? voicedSeconds,
    double? childVoicedSeconds,
    bool? isComplete,
    SessionModel? savedSession,
    List<double>? waveform,
    List<Map<String, dynamic>>? decisionTrace,
    Map<String, MyChildAnswer>? questionnaireAnswers,
    MyChildState? questionnaireState,
    MyChildEvaluation? questionnaireEvaluation,
  }) {
    return SessionState(
      childProfile: childProfile ?? this.childProfile,
      result: result ?? this.result,
      vttlMs: vttlMs ?? this.vttlMs,
      pfvStd: pfvStd ?? this.pfvStd,
      cvrRatio: cvrRatio ?? this.cvrRatio,
      audioSource: audioSource ?? this.audioSource,
      analysisStatus: analysisStatus ?? this.analysisStatus,
      qualityReasons: qualityReasons ?? this.qualityReasons,
      transitionCount: transitionCount ?? this.transitionCount,
      voicedSeconds: voicedSeconds ?? this.voicedSeconds,
      childVoicedSeconds: childVoicedSeconds ?? this.childVoicedSeconds,
      isComplete: isComplete ?? this.isComplete,
      savedSession: savedSession ?? this.savedSession,
      waveform: waveform ?? this.waveform,
      decisionTrace: decisionTrace ?? this.decisionTrace,
      questionnaireAnswers: questionnaireAnswers ?? this.questionnaireAnswers,
      questionnaireState: questionnaireState ?? this.questionnaireState,
      questionnaireEvaluation:
          questionnaireEvaluation ?? this.questionnaireEvaluation,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier([this._ref]) : super(const SessionState());

  final Ref? _ref;

  void setChildProfile(ChildProfile profile) {
    state = state.copyWith(childProfile: profile);
  }

  void setQuestionnaire(
    Map<String, MyChildAnswer> answers,
    MyChildEvaluation evaluation,
  ) {
    state = state.copyWith(
      questionnaireAnswers: answers,
      questionnaireState: evaluation.state,
      questionnaireEvaluation: evaluation,
    );
  }

  void setResult({
    required BiomarkerResult result,
    required double vttlMs,
    required double pfvStd,
    required double cvrRatio,
    required String audioSource,
    String analysisStatus = 'COMPLETE',
    List<String> qualityReasons = const [],
    int transitionCount = 0,
    double voicedSeconds = 0,
    double childVoicedSeconds = 0,
    List<double> waveform = const [],
    List<Map<String, dynamic>> decisionTrace = const [],
  }) {
    state = state.copyWith(
      result: result,
      vttlMs: vttlMs,
      pfvStd: pfvStd,
      cvrRatio: cvrRatio,
      audioSource: audioSource,
      analysisStatus: analysisStatus,
      qualityReasons: qualityReasons,
      transitionCount: transitionCount,
      voicedSeconds: voicedSeconds,
      childVoicedSeconds: childVoicedSeconds,
      waveform: waveform,
      decisionTrace: decisionTrace,
    );
  }

  /// Save the completed session to local SQLite.
  Future<void> completeSession(String workerName) async {
    final profile = state.childProfile;
    final result = state.result;
    if (profile == null || result == null) return;

    final session = SessionModel(
      id: const Uuid().v4(),
      anganwadiId: profile.anganwadiId,
      workerName: workerName,
      childName: profile.childName,
      childAgeMonths: profile.childAgeMonths,
      childBirthDate: profile.birthDate,
      gestationalWeeks: profile.gestationalWeeks,
      sessionDate: DateTime.now(),
      riskLevel: result.riskLevel,
      vttlMs: state.vttlMs,
      pfvStd: state.pfvStd,
      cvrRatio: state.cvrRatio,
      vttlFlagged: result.vttlFlagged,
      pfvFlagged: result.pfvFlagged,
      cvrFlagged: result.cvrFlagged,
      pfvRawSemitoneSD: result.pfvRawSemitoneSD,
      pfvAgeZScore: result.pfvAgeZScore,
      pfvFramesUsed: result.pfvFramesUsed,
      pfvInsufficientData: result.pfvInsufficientData,
      pfvUnit: 'semitones',
      audioSourceUsed: state.audioSource,
      districtCode: profile.districtCode,
      childUuid: profile.childUuid,
      analysisStatus: state.analysisStatus,
      qualityReasons: state.qualityReasons,
      transitionCount: state.transitionCount,
      voicedSeconds: state.voicedSeconds,
      childVoicedSeconds: state.childVoicedSeconds,
      questionnaireRunId: const Uuid().v4(),
      consentId: const Uuid().v4(),
      questionnaireState: state.questionnaireState?.name,
      questionnaireAnswers: state.questionnaireAnswers.map(
        (key, value) => MapEntry(key, value.name),
      ),
      questionnaireAnalysis:
          state.questionnaireEvaluation?.toJson() ?? const {},
      decisionTrace: state.decisionTrace,
      waveform: state.waveform,
    );

    await SessionRepository().saveSession(session);
    state = state.copyWith(isComplete: true, savedSession: session);
    // The home screen can still be mounted behind the result route. Refresh
    // its cached history immediately so a saved screening is visible as soon
    // as the worker returns home.
    _ref?.invalidate(pastSessionsProvider);
  }

  void reset() {
    state = const SessionState();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((
  ref,
) {
  return SessionNotifier(ref);
});

/// Provider for past sessions list.
final pastSessionsProvider = FutureProvider<List<SessionModel>>((ref) async {
  return SessionRepository().getRecentSessions();
});
