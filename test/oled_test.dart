import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

import 'package:newtube/state/app_state.dart';

void main() {
  testWidgets('oled theme makes surfaces black', (tester) async {
    SharedPreferences.setMockInitialValues({'theme': 'oled'});
    final prefs = await SharedPreferences.getInstance();
    final state = await testState(prefs: prefs);

    await tester.pumpWidget(AppScope(state: state, child: const NewtubeApp()));
    await tester.pump();
    final theme = tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .darkTheme!;
    expect(theme.colorScheme.surface, Colors.black);
    expect(theme.colorScheme.surfaceContainerHigh, Colors.black);
    expect(theme.scaffoldBackgroundColor, Colors.black);
    expect(theme.dialogTheme.backgroundColor, Colors.black);
  });
}
