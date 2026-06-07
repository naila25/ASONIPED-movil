import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asoniped_movil/main.dart';

void main() {
  testWidgets('App loads login route definitions', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
