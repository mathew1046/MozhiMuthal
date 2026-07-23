import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mozhimuthal/data/models/child_profile.dart';
import 'package:mozhimuthal/domain/my_child_engine.dart';
import 'package:mozhimuthal/main.dart';
import 'package:mozhimuthal/presentation/providers/session_provider.dart';
import 'package:mozhimuthal/presentation/screens/questionnaire/questionnaire_screen.dart';

void main() {
  testWidgets('App renders and navigates to home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MozhiMuthalApp()));

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets(
    'questionnaire starts unanswered and advances one card at a time',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(576, 1280));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final session = SessionNotifier();
      session.setChildProfile(
        ChildProfile(
          childUuid: 'test-child',
          childAgeMonths: 24,
          birthDate: DateTime(2024, 1, 1),
          anganwadiId: 'test-centre',
          districtCode: 'test-district',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sessionProvider.overrideWith((ref) => session)],
          child: const MaterialApp(home: QuestionnaireScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final total = MyChildEngine.forAge(24).length;
      expect(total, lessThanOrEqualTo(20));
      expect(find.text('Question 1 of $total'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Achieved'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Question 2 of $total'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
