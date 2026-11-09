import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Directory _repoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync()) {
      final text = pubspec.readAsStringSync();
      if (text.contains('name: vet45') &&
          Directory('${dir.path}/apps').existsSync() &&
          Directory('${dir.path}/packages').existsSync()) {
        return dir;
      }
    }
    dir = dir.parent;
  }
  fail('Could not locate repo root from ${Directory.current.path}');
}

Iterable<File> _dartFilesUnder(Directory dir) {
  if (!dir.existsSync()) return const [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
}

bool _isTestPath(String path) {
  return path.contains('/test/') ||
      path.endsWith('_test.dart') ||
      path.contains('/testing/');
}

void main() {
  late final Directory root;

  setUpAll(() {
    root = _repoRoot();
  });

  test('presentation.dart does not export Fake* or testing paths', () {
    final source = File(
      '${root.path}/apps/erp/lib/features/iam/presentation.dart',
    ).readAsStringSync();
    expect(source.contains('Fake'), isFalse);
    expect(source.contains('testing/'), isFalse);
    expect(source.contains('/mock/'), isFalse);
  });

  test('IAM presentation lib (non-testing) does not import Fake*Data', () {
    final lib = Directory('${root.path}/apps/erp/lib/features/iam/presentation');
    final violations = <String>[];
    for (final file in _dartFilesUnder(lib)) {
      if (_isTestPath(file.path) || file.path.endsWith('/testing.dart')) {
        continue;
      }
      if (file.path.contains('/src/testing/')) continue;
      final text = file.readAsStringSync();
      if (RegExp(r'Fake[A-Za-z]+Data').hasMatch(text) ||
          text.contains('src/testing/') ||
          text.contains('/mock/')) {
        violations.add(file.path.replaceFirst('${root.path}/', ''));
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('ERP production lib has no TH-01 Fake*Data or testing imports', () {
    final targets = [
      Directory('${root.path}/apps/erp/lib'),
    ];
    final violations = <String>[];
    final pattern = RegExp(
      r'Fake[A-Za-z]+Data|/src/testing/|/mock/',
    );
    for (final dir in targets) {
      for (final file in _dartFilesUnder(dir)) {
        if (_isTestPath(file.path)) continue;
        final text = file.readAsStringSync();
        if (pattern.hasMatch(text)) {
          violations.add(file.path.replaceFirst('${root.path}/', ''));
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('ERP my-account edit route has no MyAccountUiModel.sample fallback', () {
    final router = File(
      '${root.path}/apps/erp/lib/core/router/app_router.dart',
    ).readAsStringSync();
    expect(router.contains('MyAccountUiModel.sample'), isFalse);
    expect(
      router.contains("path: '/more/my-account/edit'"),
      isTrue,
    );
  });

  test('S4/S5 role routes redirect away from fake role UI', () {
    final router = File(
      '${root.path}/apps/erp/lib/core/router/app_router.dart',
    ).readAsStringSync();
    expect(router.contains("path: '/more/roles'"), isTrue);
    expect(router.contains("path: '/more/roles/detail'"), isTrue);
    expect(router.contains("path: '/more/users/select-role'"), isTrue);
    expect(router.contains("path: '/more/users/preview-role-change'"), isTrue);
    final rolesIdx = router.indexOf("path: '/more/roles'");
    expect(rolesIdx, greaterThanOrEqualTo(0));
    final rolesWindow = router.substring(rolesIdx, router.indexOf('GoRoute(', rolesIdx + 1));
    expect(rolesWindow.contains('OrganizationRolesPage'), isTrue);
    expect(rolesWindow.contains('redirect:'), isFalse);
    for (final path in [
      '/more/roles/detail',
      '/more/users/select-role',
      '/more/users/preview-role-change',
    ]) {
      final idx = router.indexOf("path: '$path'");
      expect(idx, greaterThanOrEqualTo(0), reason: path);
      final window = router.substring(idx, idx + 220);
      expect(window.contains('redirect:'), isTrue, reason: path);
      expect(window.contains('OrganizationRolesPage'), isFalse, reason: path);
    }
  });

  test('invitation route has no raw token path parameter', () {
    final router = File(
      '${root.path}/apps/erp/lib/core/router/app_router.dart',
    ).readAsStringSync();
    expect(router.contains(':token'), isFalse);
    expect(router.contains("path: '/invitation'"), isTrue);
  });
}
