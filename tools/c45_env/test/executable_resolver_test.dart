import 'dart:io';

import 'package:test/test.dart';
import 'package:c45_env/executable_resolver.dart';

void main() {
  group('resolveExecutable', () {
    test('returns name unchanged on non-Windows', () {
      if (Platform.isWindows) {
        return;
      }
      expect(resolveExecutable('flutter'), 'flutter');
    });

    test('returns explicit path unchanged on Windows', () {
      if (!Platform.isWindows) {
        return;
      }
      const path = r'C:\tools\flutter.bat';
      expect(resolveExecutable(path), path);
    });

    test('useShellOnWindows is true for bare command names', () {
      if (!Platform.isWindows) {
        expect(useShellOnWindows('flutter'), isFalse);
        return;
      }
      expect(useShellOnWindows('flutter'), isTrue);
      expect(useShellOnWindows(r'C:\sdk\bin\flutter.bat'), isTrue);
      expect(useShellOnWindows(r'C:\sdk\bin\dart.exe'), isFalse);
    });

    test('lookupExecutableFromKnownRoots finds flutter.bat under FLUTTER_ROOT', () {
      if (!Platform.isWindows) {
        return;
      }
      final temp = Directory.systemTemp.createTempSync('c45_flutter_root_');
      addTearDown(() {
        if (temp.existsSync()) {
          temp.deleteSync(recursive: true);
        }
      });
      final binDir = Directory('${temp.path}\\bin')..createSync(recursive: true);
      final bat = File('${binDir.path}\\flutter.bat')..writeAsStringSync('@echo off\n');

      final previous = Platform.environment['FLUTTER_ROOT'];
      try {
        Platform.environment['FLUTTER_ROOT'] = temp.path;
        expect(lookupExecutableFromKnownRoots('flutter'), bat.path);
      } finally {
        if (previous == null) {
          Platform.environment.remove('FLUTTER_ROOT');
        } else {
          Platform.environment['FLUTTER_ROOT'] = previous;
        }
      }
    });
  });
}
