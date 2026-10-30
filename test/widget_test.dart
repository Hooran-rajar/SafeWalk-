import 'package:flutter_test/flutter_test.dart';
import 'package:safewalk/main.dart';

void main() {
  testWidgets('SafeWalk app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const SafeWalkApp(firebaseReady: false));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to SafeWalk'), findsOneWidget);
  });
}
