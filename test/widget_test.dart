import 'package:flutter_test/flutter_test.dart';
import 'package:notes_taker/app/app.dart';
import 'package:notes_taker/app/app_config.dart';

void main() {
  testWidgets('shows splash page', (WidgetTester tester) async {
    await tester.pumpWidget(NotesTakerApp(config: AppConfig.staging()));

    expect(find.text('Notes Taker'), findsOneWidget);
  });
}
