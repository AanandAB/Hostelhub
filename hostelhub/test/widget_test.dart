import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hostelhub/main.dart';

void main() {
  setUpAll(() {
    // Avoid network font fetch in the test environment.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('splash redirects to login when signed out', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: HostelHubApp()));
    await tester.pumpAndSettle();
    expect(find.text('Log in'), findsOneWidget);
  });
}
