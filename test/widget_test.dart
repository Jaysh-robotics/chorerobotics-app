import 'package:flutter_test/flutter_test.dart';
import 'package:chorerobotics/main.dart';

void main() {
  testWidgets('App renders', (tester) async {
    await tester.pumpWidget(const ChoreRoboticsApp());
    expect(find.text('ChoreRobotics'), findsAny);
  });
}
