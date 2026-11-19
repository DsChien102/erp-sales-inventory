import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';
import 'package:c45_env/tui/c45_tui_theme.dart';

void main() {
  group('C45TuiTheme', () {
    test('dark mirrors VColorScheme.dark primary/semantic tokens', () {
      final t = C45TuiTheme.dark;
      expect(t.brightness, Brightness.dark);
      expect(t.primary, const Color(0x5FB36C)); // primary400
      expect(t.background, const Color(0x0E1116)); // neutral900
      expect(t.surface, const Color(0x2F3640)); // neutral700
      expect(t.error, const Color(0xD14343)); // danger
      expect(t.success, const Color(0x2E9E4B));
      expect(t.warning, const Color(0xD98A0B));
      expect(t.selectionColor, const Color(0x163A1C)); // primary900
    });

    test('light mirrors VColorScheme.light primary/semantic tokens', () {
      final t = C45TuiTheme.light;
      expect(t.brightness, Brightness.light);
      expect(t.primary, const Color(0x3B9448)); // primary500
      expect(t.background, const Color(0xF6F8F9));
      expect(t.surface, const Color(0xFFFFFF));
      expect(t.error, const Color(0xD14343));
      expect(t.success, const Color(0x2E9E4B));
      expect(t.warning, const Color(0xD98A0B));
      expect(t.selectionColor, const Color(0xDCEFDE)); // primary100
    });
  });
}
