import 'package:flutter_test/flutter_test.dart';
import 'package:notes_taker/app/app.dart';
import 'package:notes_taker/app/app_config.dart';

void main() {
  testWidgets('shows splash then opens login', (WidgetTester tester) async {
    await tester.pumpWidget(NotesTakerApp(config: AppConfig.staging()));

    expect(find.text('Notes Taker'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2999));

    expect(find.text('Notes Taker'), findsOneWidget);
    expect(find.text('Login'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });
}
