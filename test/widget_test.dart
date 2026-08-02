import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_taker/app/app.dart';
import 'package:notes_taker/app/app_config.dart';

void main() {
  testWidgets('shows splash then opens notes', (WidgetTester tester) async {
    await tester.pumpWidget(NotesTakerApp(config: AppConfig.staging()));

    expect(find.text('Offline Notes'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1799));

    expect(find.text('Offline Notes'), findsOneWidget);
    expect(find.byTooltip('New note'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(find.byTooltip('New note'), findsOneWidget);
    expect(find.text('No notes yet'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Press back again to exit.'), findsOneWidget);
  });

  testWidgets('creates a note from the home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(NotesTakerApp(config: AppConfig.staging()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('New note'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'Trip checklist');
    await tester.enterText(fields.at(1), 'Passport and charger');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Trip checklist'), findsOneWidget);
  });
}
