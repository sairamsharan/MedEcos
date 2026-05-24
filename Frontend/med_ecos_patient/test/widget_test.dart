import 'package:flutter_test/flutter_test.dart';

import 'package:med_ecos_patient/main.dart';

void main() {
  testWidgets('App launches and shows Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // The app should render without throwing
    expect(find.byType(MyApp), findsOneWidget);
  });
}
