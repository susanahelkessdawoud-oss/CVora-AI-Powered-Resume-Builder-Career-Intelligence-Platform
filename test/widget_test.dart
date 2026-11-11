// Widget smoke test for the CV/Resume type picker.
//
// This screen doesn't touch Supabase or platform plugins, so it can be
// pumped directly without initializing the backend — a good sanity check
// that the app's actual UI (not the Flutter starter counter) still builds.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cvora/Screens/builder/document_type_screen.dart';

void main() {
  testWidgets('DocumentTypeScreen lets the user pick CV or Resume', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: DocumentTypeScreen()),
    );

    expect(find.text('Create a CV'), findsOneWidget);
    expect(find.text('Create a Resume'), findsOneWidget);

    // Resume is selected by default.
    expect(find.text('Continue with Resume'), findsOneWidget);

    await tester.tap(find.text('Create a CV'));
    await tester.pump();

    expect(find.text('Continue with CV'), findsOneWidget);
  });
}
