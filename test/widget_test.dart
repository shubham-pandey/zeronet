import 'package:flutter_test/flutter_test.dart';
import 'package:zeronet/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ZeronetApp());
    expect(find.text('PROTECTED'), findsOneWidget);
  });
}
