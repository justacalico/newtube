import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/ui/shell/app_shell.dart';

import 'fakes.dart';

void main() {
  testWidgets('navbar hides during pip', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final pip = FakePipActions();
    final state = await testState(pipActions: pip);

    await pumpPage(tester, state, const AppShell(), size: const Size(400, 800));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    pip.pipMode.value = true;
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    pip.pipMode.value = false;
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
