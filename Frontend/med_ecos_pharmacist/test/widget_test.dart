import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_ecos_pharmacist/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MedEcosPharmacistApp());
    expect(find.text('MedEcos'), findsOneWidget);
  });
}
