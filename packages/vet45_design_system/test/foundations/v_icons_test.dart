import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  test('key, fileCheck, unplug, and circleX resolve Lucide glyphs', () {
    expect(VIcons.key.value.fontFamily, 'Lucide');
    expect(VIcons.fileCheck.value.fontFamily, 'Lucide');
    expect(VIcons.unplug.value.fontFamily, 'Lucide');
    expect(VIcons.error.value.fontFamily, 'Lucide');
    expect(VIcons.key.value.codePoint, isNonZero);
    expect(VIcons.unplug.value.codePoint, isNonZero);
    expect(VIcons.error.value.codePoint, 57476);
  });
}
