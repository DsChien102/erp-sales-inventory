import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  test('key, fileCheck, file, fileText, unplug, and circleX resolve Lucide glyphs',
      () {
    expect(VIcons.key.value.fontFamily, 'Lucide');
    expect(VIcons.fileCheck.value.fontFamily, 'Lucide');
    expect(VIcons.file.value.fontFamily, 'Lucide');
    expect(VIcons.fileText.value.fontFamily, 'Lucide');
    expect(VIcons.unplug.value.fontFamily, 'Lucide');
    expect(VIcons.error.value.fontFamily, 'Lucide');
    expect(VIcons.key.value.codePoint, isNonZero);
    expect(VIcons.file.value.codePoint, 57536);
    expect(VIcons.fileText.value.codePoint, 57548);
    expect(VIcons.unplug.value.codePoint, isNonZero);
    expect(VIcons.error.value.codePoint, 57476);
  });
}
