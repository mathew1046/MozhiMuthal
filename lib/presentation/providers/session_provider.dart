import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/child_profile.dart';
import '../../data/models/biomarker_result.dart';
import '../../data/models/session_model.dart';
import '../../data/repositories/session_repository.dart';
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

  const SessionState({
    this.childProfile,
    this.result,
    this.vttlMs = 0,
    this.pfvStd = 0,
    this.cvrRatio = 0,
    this.audioSource = 'MOCK',
    this.isComplete = false,
  });

  SessionState copyWith({
    ChildProfile? childProfile,
    BiomarkerResult? result,
    double? vttlMs,
    double? pfvStd,
    double? cvrRatio,
    String? audioSource,
    bool? isComplete,
  }) {
    return SessionState(
      childProfile: childProfile ?? this.childProfile,
      result: result ?? this.result,
      vttlMs: vttlMs ?? this.vttlMs,
      pfvStd: pfvStd ?? this.pfvStd,
      cvrRatio: cvrRatio ?? this.cvrRatio,
      audioSource: audioSource ?? this.audioSource,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(const SessionState());

  void setChildProfile(ChildProfile profile) {
    state = state.copyWith(childProfile: profile);
  }

  void setResult({
    required BiomarkerResult result,
    required double vttlMs,
    required double pfvStd,
    required double cvrRatio,
    required String audioSource,
  }) {
    state = state.copyWith(
      result: result,
      vttlMs: vttlMs,
      pfvStd: pfvStd,
      cvrRatio: cvrRatio,
      audioSource: audioSource,
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
      sessionDate: DateTime.now(),
      riskLevel: result.riskLevel,
      vttlMs: state.vttlMs,
      pfvStd: state.pfvStd,
      cvrRatio: state.cvrRatio,
      vttlFlagged: result.vttlFlagged,
      pfvFlagged: result.pfvFlagged,
      cvrFlagged: result.cvrFlagged,
      audioSourceUsed: state.audioSource,
      districtCode: profile.districtCode,
    );

    await SessionRepository().saveSession(session);
    state = state.copyWith(isComplete: true);
  }

  void reset() {
    state = const SessionState();
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier();
});

/// Provider for past sessions list.
final pastSessionsProvider = FutureProvider<List<SessionModel>>((ref) async {
  return SessionRepository().getRecentSessions();
});
