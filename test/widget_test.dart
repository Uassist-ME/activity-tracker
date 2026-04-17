import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:activity_tracker/main.dart';

void main() {
  testWidgets('shows login screen when no token is stored', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ActivityTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Activity Tracker'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
