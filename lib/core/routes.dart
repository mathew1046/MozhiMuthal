import 'package:go_router/go_router.dart';

import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/child_profile/child_profile_screen.dart';
import '../presentation/screens/consent/consent_screen.dart';
import '../presentation/screens/elicitation/elicitation_screen.dart';
import '../presentation/screens/processing/processing_screen.dart';
import '../presentation/screens/result/result_screen.dart';
import '../presentation/screens/referral/referral_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/history/result_history_screen.dart';
import '../presentation/screens/history/session_detail_screen.dart';
import '../presentation/screens/questionnaire/questionnaire_screen.dart';
import '../data/models/session_model.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/child-profile',
      builder: (context, state) => const ChildProfileScreen(),
    ),
    GoRoute(
      path: '/questionnaire',
      builder: (context, state) => const QuestionnaireScreen(),
    ),
    GoRoute(
      path: '/consent',
      builder: (context, state) => const ConsentScreen(),
    ),
    GoRoute(
      path: '/elicitation',
      builder: (context, state) => const ElicitationScreen(),
    ),
    GoRoute(
      path: '/processing',
      builder: (context, state) => const ProcessingScreen(),
    ),
    GoRoute(path: '/result', builder: (context, state) => const ResultScreen()),
    GoRoute(
      path: '/referral',
      builder: (context, state) => const ReferralScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const ResultHistoryScreen(),
    ),
    GoRoute(
      path: '/session-detail',
      builder: (context, state) {
        final session = state.extra;
        if (session is! SessionModel) {
          return const SessionDetailMissingScreen();
        }
        return SessionDetailScreen(session: session);
      },
    ),
  ],
);
