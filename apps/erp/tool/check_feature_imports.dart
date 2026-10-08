import 'dart:io';

/// Chặn import sai tầng / sai feature cho code mới trong `lib/features`.
///
/// R1, R2 chỉ xét nguồn `data/` và `logic/`. R3 xét mọi file trong `lib/features`
/// (kể cả `presentation/`).
///
/// Chạy từ `apps/erp`: `dart run tool/check_feature_imports.dart`
void main() {
  final features = Directory('lib/features');
  if (!features.existsSync()) {
    stderr.writeln('Không thấy lib/features. Chạy từ thư mục apps/erp.');
    exit(1);
  }

  final violations = <String>[];
  for (final entity in features.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final source = _locate(entity.path);
    if (source == null) continue;
    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final uri = _importUri(lines[i]);
      if (uri == null) continue;
      final target = _resolve(entity, uri);
      final rule = _rule(source: source, importUri: uri, target: target);
      if (rule == null) continue;
      violations.add('${_display(entity.path)}:${i + 1}  $rule  $uri');
    }
  }

  if (violations.isEmpty) return;
  for (final violation in violations) {
    stdout.writeln(violation);
  }
  exit(1);
}

final class _Place {
  const _Place(this.feature, this.layer);

  final String feature;
  final String layer;
}

final _placePattern = RegExp(r'features/([^/]+)/(data|logic|presentation)(?:/|$)');

_Place? _locate(String path) {
  final normalized = path.replaceAll('\\', '/');
  final match = _placePattern.firstMatch(normalized);
  if (match == null) return null;
  return _Place(match.group(1)!, match.group(2)!);
}

final _importPattern = RegExp('^\\s*(?:import|export)\\s+[\'"]([^\'"]+)[\'"]');

String? _importUri(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('//') || trimmed.startsWith('/*') || trimmed.startsWith('*')) {
    return null;
  }
  return _importPattern.firstMatch(line)?.group(1);
}

_Place? _resolve(File file, String uri) {
  if (uri.startsWith('package:erp/')) {
    return _locate(uri.substring('package:erp/'.length));
  }
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return null;
  final joined = _normalize('${_dir(file.path)}/$uri');
  return _locate(joined);
}

String? _rule({
  required _Place source,
  required String importUri,
  required _Place? target,
}) {
  if (source.layer == 'data') {
    if (importUri.startsWith('package:flutter/') &&
        importUri != 'package:flutter/foundation.dart') {
      return 'R1';
    }
    if (target != null && (target.layer == 'logic' || target.layer == 'presentation')) {
      return 'R1';
    }
  }
  if (source.layer == 'logic' && target != null && target.layer == 'presentation') {
    return 'R2';
  }
  if (target != null && target.layer == 'logic' && target.feature != source.feature) {
    return 'R3';
  }
  return null;
}

String _display(String path) => path.replaceAll('\\', '/').replaceFirst(RegExp(r'^\./'), '');

String _dir(String path) {
  final normalized = path.replaceAll('\\', '/');
  final slash = normalized.lastIndexOf('/');
  return slash < 0 ? '' : normalized.substring(0, slash);
}

String _normalize(String path) {
  final parts = <String>[];
  for (final part in path.replaceAll('\\', '/').split('/')) {
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (parts.isNotEmpty) parts.removeLast();
      continue;
    }
    parts.add(part);
  }
  return parts.join('/');
}
