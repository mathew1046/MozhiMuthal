import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mozhimuthal/main.dart';

void main() {
  testWidgets('App renders and navigates to home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MozhiMuthalApp()));

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
