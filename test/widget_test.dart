import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notes_taker/app/app.dart';
import 'package:notes_taker/app/app_config.dart';
import 'package:notes_taker/features/notes/data/notes_repository.dart';
import 'package:notes_taker/features/notes/domain/entities/note.dart';

void main() {
  late _MockNotesRepository repository;
  late StreamController<List<Note>> notesController;

  setUp(() {
    repository = _MockNotesRepository();
    notesController = StreamController<List<Note>>.broadcast();
    when(
      () => repository.watchNotes(),
    ).thenAnswer((_) => notesController.stream);
    when(
      () => repository.connectionChanges,
    ).thenAnswer((_) => const Stream.empty());
    when(() => repository.isOnline).thenReturn(true);
    when(() => repository.start()).thenAnswer((_) async {});
    when(() => repository.stop()).thenAnswer((_) async {});
    when(
      () => repository.create(
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((invocation) async {
      notesController.add([
        Note(
          id: 'local-test',
          title: invocation.namedArguments[#title] as String,
          body: invocation.namedArguments[#body] as String,
          updatedAt: DateTime(2026),
          status: SyncStatus.pending,
        ),
      ]);
    });
  });

  tearDown(() async {
    await notesController.close();
  });

  testWidgets('shows splash then opens notes', (WidgetTester tester) async {
    await tester.pumpWidget(
      NotesTakerApp(config: AppConfig.staging(), notesRepository: repository),
    );

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Initializing local database...'), findsNothing);
    final theme = Theme.of(tester.element(find.text('Notes')));
    expect(theme.textTheme.labelLarge?.color, theme.colorScheme.onSurface);
    expect(
      theme.textTheme.labelMedium?.color,
      theme.colorScheme.onSurfaceVariant,
    );

    await tester.pump(const Duration(milliseconds: 1800));
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
    await tester.pumpWidget(
      NotesTakerApp(config: AppConfig.staging(), notesRepository: repository),
    );
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

  testWidgets('back from bottom tabs returns to notes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      NotesTakerApp(config: AppConfig.staging(), notesRepository: repository),
    );
    await tester.pumpAndSettle();

    for (final tab in ['Search', 'Settings']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byTooltip('New note'), findsOneWidget);
    }
  });
}

class _MockNotesRepository extends Mock implements NotesRepository {}
