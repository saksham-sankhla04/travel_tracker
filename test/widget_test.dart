import 'package:flutter_test/flutter_test.dart';

import 'package:travel_tracker/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TravelTrackerApp());
    expect(find.text('Travel Tracker'), findsOneWidget);
    expect(find.text('Permissions'), findsOneWidget);
    expect(find.text('Trip Tracking'), findsOneWidget);
  });
}
