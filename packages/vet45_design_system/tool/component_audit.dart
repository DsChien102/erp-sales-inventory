import 'dart:io';

/// Simple YAML subset parser for contract_matrix.yaml
/// Format:
///   ClassName:
///     role: action
///     tone: required
///     ...
Map<String, _Expect> _loadMatrix(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing contract matrix: $path');
    exit(1);
  }
  final result = <String, _Expect>{};
  String? current;
  Map<String, String> fields = {};

  void flush() {
    if (current == null) return;
    result[current!] = _Expect(
      role: fields['role'] ?? 'unknown',
      tone: fields['tone'] ?? 'optional',
      emphasis: fields['emphasis'] ?? 'optional',
      state: fields['state'] ?? 'optional',
      semanticLabel: fields['semanticLabel'] ?? 'optional',
    );
    fields = {};
    current = null;
  }

  for (final raw in file.readAsLinesSync()) {
    final line = raw.split('#').first.trimRight();
    if (line.trim().isEmpty) continue;
    if (!line.startsWith(' ') && !line.startsWith('\t') && line.endsWith(':')) {
      flush();
      current = line.substring(0, line.length - 1).trim();
      continue;
    }
    final trimmed = line.trim();
    final colon = trimmed.indexOf(':');
    if (colon <= 0 || current == null) continue;
    final key = trimmed.substring(0, colon).trim();
    final value = trimmed.substring(colon + 1).trim();
    fields[key] = value;
  }
  flush();
  return result;
}

final _exportPattern = RegExp(r"^export 'src/(.+\.dart)';$");
final _classPattern = RegExp(r'class\s+([A-Za-z0-9_]+)(?:<[^>]+>)?\s+');

void main(List<String> args) {
  final failOnRequired = args.contains('--fail-on-required');
  final packageRoot = Directory.current.path;
  final designSystemFile = File('$packageRoot/lib/design_system.dart');
  final matrixPath = '$packageRoot/docs/audit/contract_matrix.yaml';

  if (!designSystemFile.existsSync()) {
    stderr.writeln('Không tìm thấy lib/design_system.dart. Hãy chạy lệnh tại package root.');
    exitCode = 1;
    return;
  }

  final matrix = _loadMatrix(matrixPath);
  final lines = designSystemFile.readAsLinesSync();
  final rows = <_AuditRow>[];

  String currentSection = 'unknown';
  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.startsWith('//')) {
      currentSection = line.replaceFirst('//', '').trim().toLowerCase();
      continue;
    }

    final match = _exportPattern.firstMatch(line);
    if (match == null) continue;

    final relativeSrcPath = match.group(1)!;
    final fullPath = '$packageRoot/lib/src/$relativeSrcPath';
    final file = File(fullPath);
    final exists = file.existsSync();
    final content = exists ? file.readAsStringSync() : '';
    final classNames = exists
        ? _classPattern
            .allMatches(content)
            .map((m) => m.group(1)!)
            .where((n) => !n.startsWith('_'))
            .toSet()
            .toList()
        : <String>[];

    final isAuditedCategory = currentSection.contains('primitives') ||
        currentSection.contains('components') ||
        currentSection.contains('business') ||
        currentSection.contains('patterns') ||
        currentSection.contains('forms');
    if (!isAuditedCategory) continue;

    // Skip form validators/formatters/models — only widget exports
    if (relativeSrcPath.contains('/validators/') ||
        relativeSrcPath.contains('/formatters/') ||
        relativeSrcPath.contains('/models/')) {
      continue;
    }

    final primary = _primaryClass(classNames, relativeSrcPath);
    final expect = matrix[primary];
    final hasTone = content.contains('VComponentTone');
    final hasEmphasis = content.contains('VComponentEmphasis');
    final hasState = content.contains('VComponentState');
    final hasSemanticLabel = content.contains('semanticLabel');
    final hasSemantics = content.contains('Semantics(');

    final toneStatus = _status(expect?.tone, hasTone);
    final emphasisStatus = _status(expect?.emphasis, hasEmphasis);
    final stateStatus = _status(expect?.state, hasState);
    final labelStatus = _status(expect?.semanticLabel, hasSemanticLabel);

    rows.add(
      _AuditRow(
        category: _normalizeCategory(currentSection),
        exportPath: 'src/$relativeSrcPath',
        exists: exists,
        classNames: classNames,
        primaryClass: primary,
        role: expect?.role ?? 'unmapped',
        hasSemantics: hasSemantics,
        hasTone: hasTone,
        hasEmphasis: hasEmphasis,
        hasState: hasState,
        hasSemanticLabel: hasSemanticLabel,
        toneExpect: expect?.tone ?? 'optional',
        emphasisExpect: expect?.emphasis ?? 'optional',
        stateExpect: expect?.state ?? 'optional',
        semanticLabelExpect: expect?.semanticLabel ?? 'optional',
        toneStatus: toneStatus,
        emphasisStatus: emphasisStatus,
        stateStatus: stateStatus,
        semanticLabelStatus: labelStatus,
      ),
    );
  }

  final generatedAt = DateTime.now().toIso8601String();

  final reportDir = Directory('$packageRoot/docs/audit');
  if (!reportDir.existsSync()) reportDir.createSync(recursive: true);
  final reportFile = File('${reportDir.path}/component_audit_report.md');
  reportFile.writeAsStringSync(_buildReport(rows, generatedAt));

  final snapshotDir = Directory('$packageRoot/lib/src/audit');
  if (!snapshotDir.existsSync()) snapshotDir.createSync(recursive: true);
  final snapshotFile = File('${snapshotDir.path}/v_component_audit_snapshot.dart');
  snapshotFile.writeAsStringSync(_buildDartSnapshot(rows, generatedAt));

  stdout.writeln('Đã tạo báo cáo audit: ${reportFile.path}');
  stdout.writeln('Đã tạo Dart snapshot: ${snapshotFile.path}');
  stdout.writeln(_buildSummary(rows));

  final missingRequired = rows
      .expand(
        (r) => [
          if (r.toneStatus == 'missing_required') '${r.primaryClass}.tone',
          if (r.emphasisStatus == 'missing_required') '${r.primaryClass}.emphasis',
          if (r.stateStatus == 'missing_required') '${r.primaryClass}.state',
          if (r.semanticLabelStatus == 'missing_required')
            '${r.primaryClass}.semanticLabel',
        ],
      )
      .toList();

  if (failOnRequired && missingRequired.isNotEmpty) {
    stderr.writeln('FAIL: missing required contracts:');
    for (final m in missingRequired) {
      stderr.writeln('  - $m');
    }
    exitCode = 1;
  }
}

String _primaryClass(List<String> classNames, String path) {
  final preferred = classNames.where((n) => n.startsWith('V')).toList();
  if (preferred.isNotEmpty) {
    // Prefer the main widget matching file stem (v_button → VButton)
    final stem = path.split('/').last.replaceAll('.dart', '');
    final guess = stem
        .split('_')
        .map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}')
        .join();
    if (preferred.contains(guess)) return guess;
    return preferred.first;
  }
  if (classNames.isNotEmpty) return classNames.first;
  return path.split('/').last;
}

String _status(String? expect, bool present) {
  final level = expect ?? 'optional';
  if (level == 'na') return present ? 'na_present' : 'na';
  if (level == 'required') return present ? 'pass' : 'missing_required';
  if (level == 'preferred') return present ? 'pass' : 'missing_preferred';
  // optional
  return present ? 'pass' : 'optional_absent';
}

String _normalizeCategory(String raw) {
  if (raw.contains('business')) return 'business';
  if (raw.contains('components')) return 'components';
  if (raw.contains('primitives')) return 'primitives';
  if (raw.contains('patterns')) return 'patterns';
  if (raw.contains('forms')) return 'forms';
  return raw;
}

String _buildReport(List<_AuditRow> rows, String generatedAt) {
  final sorted = [...rows]..sort((a, b) {
    final c = a.category.compareTo(b.category);
    if (c != 0) return c;
    return a.exportPath.compareTo(b.exportPath);
  });

  final buffer = StringBuffer()
    ..writeln('# Component Audit Report')
    ..writeln()
    ..writeln('- Generated at: `$generatedAt`')
    ..writeln('- Matrix: `docs/audit/contract_matrix.yaml`')
    ..writeln('- Scope: primitives / components / business / patterns / forms widgets')
    ..writeln()
    ..writeln(
      '| Category | Class | Role | Tone | Emphasis | State | semanticLabel | Semantics |',
    )
    ..writeln('|---|---|---|---|---|---|---|---|');

  for (final row in sorted) {
    buffer.writeln(
      '| ${row.category} | `${row.primaryClass}` | ${row.role} | '
      '${_cell(row.toneExpect, row.toneStatus)} | '
      '${_cell(row.emphasisExpect, row.emphasisStatus)} | '
      '${_cell(row.stateExpect, row.stateStatus)} | '
      '${_cell(row.semanticLabelExpect, row.semanticLabelStatus)} | '
      '${row.hasSemantics ? 'Yes' : 'No'} |',
    );
  }
  return buffer.toString();
}

String _cell(String expect, String status) {
  final short = switch (status) {
    'pass' => 'Pass',
    'missing_required' => 'Missing',
    'missing_preferred' => 'Pref↓',
    'optional_absent' => '—',
    'na' => 'N/A',
    'na_present' => 'N/A+',
    _ => status,
  };
  return '$short ($expect)';
}

String _buildDartSnapshot(List<_AuditRow> rows, String generatedAt) {
  final sorted = [...rows]..sort((a, b) {
    final c = a.category.compareTo(b.category);
    if (c != 0) return c;
    return a.exportPath.compareTo(b.exportPath);
  });

  final buffer = StringBuffer()
    ..writeln('// GENERATED FILE - DO NOT EDIT BY HAND.')
    ..writeln('// Generated by: dart run tool/component_audit.dart')
    ..writeln()
    ..writeln("const String vComponentAuditGeneratedAt = '$generatedAt';")
    ..writeln()
    ..writeln('class VComponentAuditEntry {')
    ..writeln('  final String category;')
    ..writeln('  final String exportPath;')
    ..writeln('  final bool exists;')
    ..writeln('  final List<String> classNames;')
    ..writeln('  final String primaryClass;')
    ..writeln('  final String role;')
    ..writeln('  final bool hasSemantics;')
    ..writeln('  final bool hasTone;')
    ..writeln('  final bool hasEmphasis;')
    ..writeln('  final bool hasState;')
    ..writeln('  final bool hasSemanticLabel;')
    ..writeln('  final String toneExpect;')
    ..writeln('  final String emphasisExpect;')
    ..writeln('  final String stateExpect;')
    ..writeln('  final String semanticLabelExpect;')
    ..writeln('  final String toneStatus;')
    ..writeln('  final String emphasisStatus;')
    ..writeln('  final String stateStatus;')
    ..writeln('  final String semanticLabelStatus;')
    ..writeln()
    ..writeln('  const VComponentAuditEntry({')
    ..writeln('    required this.category,')
    ..writeln('    required this.exportPath,')
    ..writeln('    required this.exists,')
    ..writeln('    required this.classNames,')
    ..writeln('    required this.primaryClass,')
    ..writeln('    required this.role,')
    ..writeln('    required this.hasSemantics,')
    ..writeln('    required this.hasTone,')
    ..writeln('    required this.hasEmphasis,')
    ..writeln('    required this.hasState,')
    ..writeln('    required this.hasSemanticLabel,')
    ..writeln('    required this.toneExpect,')
    ..writeln('    required this.emphasisExpect,')
    ..writeln('    required this.stateExpect,')
    ..writeln('    required this.semanticLabelExpect,')
    ..writeln('    required this.toneStatus,')
    ..writeln('    required this.emphasisStatus,')
    ..writeln('    required this.stateStatus,')
    ..writeln('    required this.semanticLabelStatus,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  bool get hasMissingRequired =>')
    ..writeln("      toneStatus == 'missing_required' ||")
    ..writeln("      emphasisStatus == 'missing_required' ||")
    ..writeln("      stateStatus == 'missing_required' ||")
    ..writeln("      semanticLabelStatus == 'missing_required';")
    ..writeln('}')
    ..writeln()
    ..writeln('const List<VComponentAuditEntry> vComponentAuditEntries = [');

  for (final row in sorted) {
    final classNamesLiteral = row.classNames
        .map((name) => "'${name.replaceAll("'", "\\'")}'")
        .join(', ');
    buffer
      ..writeln('  VComponentAuditEntry(')
      ..writeln("    category: '${row.category}',")
      ..writeln("    exportPath: '${row.exportPath}',")
      ..writeln('    exists: ${row.exists},')
      ..writeln('    classNames: [$classNamesLiteral],')
      ..writeln("    primaryClass: '${row.primaryClass}',")
      ..writeln("    role: '${row.role}',")
      ..writeln('    hasSemantics: ${row.hasSemantics},')
      ..writeln('    hasTone: ${row.hasTone},')
      ..writeln('    hasEmphasis: ${row.hasEmphasis},')
      ..writeln('    hasState: ${row.hasState},')
      ..writeln('    hasSemanticLabel: ${row.hasSemanticLabel},')
      ..writeln("    toneExpect: '${row.toneExpect}',")
      ..writeln("    emphasisExpect: '${row.emphasisExpect}',")
      ..writeln("    stateExpect: '${row.stateExpect}',")
      ..writeln("    semanticLabelExpect: '${row.semanticLabelExpect}',")
      ..writeln("    toneStatus: '${row.toneStatus}',")
      ..writeln("    emphasisStatus: '${row.emphasisStatus}',")
      ..writeln("    stateStatus: '${row.stateStatus}',")
      ..writeln("    semanticLabelStatus: '${row.semanticLabelStatus}',")
      ..writeln('  ),');
  }

  buffer.writeln('];');
  return buffer.toString();
}

String _buildSummary(List<_AuditRow> rows) {
  final total = rows.length;
  final missingReq = rows.where((e) => e.hasMissingRequired).length;
  final missingPref = rows
      .where(
        (e) =>
            e.toneStatus == 'missing_preferred' ||
            e.emphasisStatus == 'missing_preferred' ||
            e.stateStatus == 'missing_preferred' ||
            e.semanticLabelStatus == 'missing_preferred',
      )
      .length;
  return [
    'Tổng component audited: $total',
    'Missing required (any field): $missingReq/$total',
    'Missing preferred (any field): $missingPref/$total',
    'Có Semantics: ${rows.where((e) => e.hasSemantics).length}/$total',
  ].join('\n');
}

class _Expect {
  final String role;
  final String tone;
  final String emphasis;
  final String state;
  final String semanticLabel;

  const _Expect({
    required this.role,
    required this.tone,
    required this.emphasis,
    required this.state,
    required this.semanticLabel,
  });
}

class _AuditRow {
  final String category;
  final String exportPath;
  final bool exists;
  final List<String> classNames;
  final String primaryClass;
  final String role;
  final bool hasSemantics;
  final bool hasTone;
  final bool hasEmphasis;
  final bool hasState;
  final bool hasSemanticLabel;
  final String toneExpect;
  final String emphasisExpect;
  final String stateExpect;
  final String semanticLabelExpect;
  final String toneStatus;
  final String emphasisStatus;
  final String stateStatus;
  final String semanticLabelStatus;

  const _AuditRow({
    required this.category,
    required this.exportPath,
    required this.exists,
    required this.classNames,
    required this.primaryClass,
    required this.role,
    required this.hasSemantics,
    required this.hasTone,
    required this.hasEmphasis,
    required this.hasState,
    required this.hasSemanticLabel,
    required this.toneExpect,
    required this.emphasisExpect,
    required this.stateExpect,
    required this.semanticLabelExpect,
    required this.toneStatus,
    required this.emphasisStatus,
    required this.stateStatus,
    required this.semanticLabelStatus,
  });

  bool get hasMissingRequired =>
      toneStatus == 'missing_required' ||
      emphasisStatus == 'missing_required' ||
      stateStatus == 'missing_required' ||
      semanticLabelStatus == 'missing_required';
}
