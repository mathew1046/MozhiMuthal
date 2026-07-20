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
  final bool isComplete;
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
    this.isComplete = false,
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
    bool? isComplete,
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
      isComplete: isComplete ?? this.isComplete,
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
  SessionNotifier() : super(const SessionState());

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
    List<double> waveform = const [],
    List<Map<String, dynamic>> decisionTrace = const [],
  }) {
    state = state.copyWith(
      result: result,
      vttlMs: vttlMs,
      pfvStd: pfvStd,
      cvrRatio: cvrRatio,
      audioSource: audioSource,
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
    state = state.copyWith(isComplete: true);
  }

  void reset() {
    state = const SessionState();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((
  ref,
) {
  return SessionNotifier();
});

/// Provider for past sessions list.
final pastSessionsProvider = FutureProvider<List<SessionModel>>((ref) async {
  return SessionRepository().getRecentSessions();
});
