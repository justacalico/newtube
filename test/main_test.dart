import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/main.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/ui/shell/title_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('createAppState wires real services', () async {
    SharedPreferences.setMockInitialValues({'theme': 'dark'});
    final prefs = await SharedPreferences.getInstance();
    final state = await createAppState(prefs);
    expect(state.api, isNotNull);
    expect(state.settings.theme, AppTheme.dark);
    expect(state.windowActions != null, isDesktopPlatform);
    expect(state.launch, isNotNull);
    expect(state.packageInfo, isNotNull);
    expect(state.createPlayer, isNotNull);
  });
}
