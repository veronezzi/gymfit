import 'package:flutter_test/flutter_test.dart';

import 'package:gymfit/main.dart';

void main() {
  testWidgets('App inicializa', (WidgetTester tester) async {
    await tester.pumpWidget(const GymFitApp());
    expect(find.text('GymFit'), findsWidgets);
  });
}
