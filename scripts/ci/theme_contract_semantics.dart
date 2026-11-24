import 'dart:io';

final class ContractSemanticIssue implements Comparable<ContractSemanticIssue> {
  const ContractSemanticIssue({
    required this.theme,
    required this.slice,
    required this.rule,
    required this.detail,
  });

  final String theme;
  final String slice;
  final String rule;
  final String detail;

  @override
  int compareTo(ContractSemanticIssue other) => '$slice|$rule|$detail'
      .compareTo('${other.slice}|${other.rule}|${other.detail}');

  @override
  String toString() => 'ERROR: theme=$theme slice=$slice rule=$rule — $detail';
}

final class ContractSymbolRow {
  const ContractSymbolRow({required this.symbol, required this.successType});

  final String symbol;
  final String? successType;
}

final class ScenarioRow {
  const ScenarioRow({required this.id, required this.response});

  final String id;
  final String response;
}

final class SemanticConfig {
  const SemanticConfig({
    required this.themeDir,
    required this.applicationBarrel,
    required this.iamFakeScenarioFile,
    required this.notifyFakeScenarioFile,
    required this.testRoot,
  });

  final Directory themeDir;
  final File applicationBarrel;
  final File iamFakeScenarioFile;
  final File notifyFakeScenarioFile;
  final Directory testRoot;
}

void main(List<String> args) {
  final config = _parseArgs(args);
  if (config == null) {
    stderr.writeln(
      'Usage: dart run theme_contract_semantics.dart '
      '--theme-dir <dir> --application-barrel <file> '
      '--iam-fake-scenario-file <file> --notify-fake-scenario-file <file> '
      '--test-root <dir>',
    );
    exitCode = 64;
    return;
  }

  final issues = inspectTheme(config)..sort();
  for (final issue in issues) {
    stderr.writeln(issue);
  }
  if (issues.isNotEmpty) {
    exitCode = 1;
  }
}

SemanticConfig? _parseArgs(List<String> args) {
  final values = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) {
      continue;
    }
    if (i + 1 >= args.length) {
      return null;
    }
    values[arg.substring(2)] = args[++i];
  }

  const required = [
    'theme-dir',
    'application-barrel',
    'iam-fake-scenario-file',
    'notify-fake-scenario-file',
    'test-root',
  ];
  for (final key in required) {
    if (!values.containsKey(key) || values[key]!.trim().isEmpty) {
      return null;
    }
  }

  return SemanticConfig(
    themeDir: Directory(values['theme-dir']!),
    applicationBarrel: File(values['application-barrel']!),
    iamFakeScenarioFile: File(values['iam-fake-scenario-file']!),
    notifyFakeScenarioFile: File(values['notify-fake-scenario-file']!),
    testRoot: Directory(values['test-root']!),
  );
}

List<ContractSemanticIssue> inspectTheme(SemanticConfig config) {
  final issues = <ContractSemanticIssue>[];
  final segments = config.themeDir.uri.pathSegments
      .where((e) => e.isNotEmpty)
      .toList();
  if (segments.isEmpty) return issues;
  final theme = segments.last;

  final roadmap = File('${config.themeDir.path}/harness/04-slice-roadmap.md');
  final contracts = File('${config.themeDir.path}/harness/07-api-contracts.md');
  final appendices = File('${config.themeDir.path}/APPENDICES.md');
  if (!roadmap.existsSync() ||
      !contracts.existsSync() ||
      !appendices.existsSync()) {
    return issues;
  }

  final activeSlices = activeContractSlices(roadmap.readAsStringSync());
  final sections = contractSections(contracts.readAsStringSync());
  final cmdCatalog = parseCmdCatalog(contracts.readAsStringSync());
  final exportedFiles = resolveExportedDartFiles(config.applicationBarrel);
  final resultTypes = parseCqrsResultTypes(exportedFiles.values);
  final iamScenarioMembers = _parseEnumMembers(
    config.iamFakeScenarioFile,
    'FakeIamScenario',
  );
  final notifyScenarioMembers = _parseEnumMembers(
    config.notifyFakeScenarioFile,
    'FakeEmailDeliveryScenario',
  );
  final scenarioRefs = _collectScenarioRefs(config.testRoot);

  final activeRows = <String, List<ContractSymbolRow>>{};
  final scenarioRows = <String, List<ScenarioRow>>{};
  for (final slice in activeSlices) {
    final section = sections[slice];
    if (section == null) {
      continue;
    }
    activeRows[slice] = parseSymbolRows(slice, section);
    scenarioRows[slice] = parseScenarioRows(slice, section);
  }

  _validateExportAndResultTypes(
    theme: theme,
    rowsBySlice: activeRows,
    resultTypes: resultTypes,
    issues: issues,
  );
  _validateCmdCatalog(
    theme: theme,
    rowsBySlice: activeRows,
    cmdCatalog: cmdCatalog,
    issues: issues,
  );
  _validateScenarios(
    theme: theme,
    rowsBySlice: scenarioRows,
    iamScenarioMembers: iamScenarioMembers,
    notifyScenarioMembers: notifyScenarioMembers,
    scenarioRefs: scenarioRefs,
    issues: issues,
  );

  return issues;
}

Set<String> activeContractSlices(String roadmap) {
  final slices = <String>{};
  for (final line in roadmap.split('\n')) {
    if (!line.trimLeft().startsWith('|')) continue;
    if (line.contains('| #') || line.contains('| --------')) continue;
    final cells = line
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cells.length < 5) continue;
    final slice = cells[0];
    final contract = cells[3];
    if (!RegExp(r'^S([0-9]+|-NOTIFY)$').hasMatch(slice)) continue;
    if (contract == 'out_of_scope') continue;
    if (contract == 'done' || contract == 'in_progress') {
      slices.add(slice);
    }
  }
  return slices;
}

Map<String, String> contractSections(String contracts) {
  final sections = <String, String>{};
  final lines = contracts.split('\n');
  String? currentSlice;
  final buffer = StringBuffer();

  void flush() {
    if (currentSlice != null) {
      sections[currentSlice] = buffer.toString();
    }
  }

  for (final line in lines) {
    final m = RegExp(r'^## §(S(?:[0-9]+|-NOTIFY))(?:\b| )').firstMatch(line);
    if (m != null) {
      flush();
      currentSlice = m.group(1)!;
      buffer.clear();
      continue;
    }
    if (currentSlice != null) {
      buffer.writeln(line);
    }
  }
  flush();
  return sections;
}

List<ContractSymbolRow> parseSymbolRows(String slice, String section) {
  final rows = <ContractSymbolRow>[];
  final lines = section.split('\n');
  var inTable = false;
  for (final line in lines) {
    if (line.contains('| Symbol |') && line.contains('| Success |')) {
      inTable = true;
      continue;
    }
    if (!inTable) continue;
    if (line.trim().isEmpty || !line.trimLeft().startsWith('|')) {
      inTable = false;
      continue;
    }
    if (line.contains('| ------')) continue;
    final cells = line
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cells.length < 4) continue;
    final symbol = _firstBackticked(cells[0]);
    if (symbol == null || !RegExp(r'(Command|Query)$').hasMatch(symbol))
      continue;
    rows.add(
      ContractSymbolRow(
        symbol: symbol,
        successType: _firstBackticked(cells[2]),
      ),
    );
  }
  return rows;
}

List<ScenarioRow> parseScenarioRows(String slice, String section) {
  final rows = <ScenarioRow>[];
  final lines = section.split('\n');
  var inTable = false;
  for (final line in lines) {
    if (line.contains('| scenario_id |')) {
      inTable = true;
      continue;
    }
    if (!inTable) continue;
    if (line.trim().isEmpty || !line.trimLeft().startsWith('|')) {
      inTable = false;
      continue;
    }
    if (line.contains('| -----------')) continue;
    final cells = line
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cells.length < 3) continue;
    final id = _firstBackticked(cells[0]) ?? cells[0].trim();
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(id)) continue;
    rows.add(
      ScenarioRow(id: id, response: _normalizeScenarioResponse(cells[2])),
    );
  }
  return rows;
}

Map<String, String> parseCmdCatalog(String appendices) {
  final map = <String, String>{};
  final lines = appendices.split('\n');
  var inCatalog = false;
  for (final line in lines) {
    if (line.trim() == '## CMD catalog overview') {
      inCatalog = true;
      continue;
    }
    if (!inCatalog) continue;
    if (line.startsWith('## §S0')) break;
    if (!line.trimLeft().startsWith('|')) continue;
    if (line.contains('| CMD ID') || line.contains('| ------')) continue;
    final cells = line
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cells.length < 2) continue;
    final id = cells[0].replaceAll('`', '');
    final symbol = _firstBackticked(cells[1]) ?? cells[1];
    if (RegExp(r'^CMD-[A-Z0-9-]+$').hasMatch(id)) {
      map[id] = symbol;
    }
  }
  return map;
}

Map<String, File> resolveExportedDartFiles(File barrel) {
  final files = <String, File>{};
  if (!barrel.existsSync()) return files;
  final dir = barrel.parent;
  final lines = barrel.readAsLinesSync();
  for (final line in lines) {
    final m = RegExp(r"export '([^']+\.dart)'").firstMatch(line);
    if (m == null) continue;
    final file = File('${dir.path}/${m.group(1)!}');
    if (file.existsSync()) {
      files[file.path] = file;
    }
  }
  return files;
}

Map<String, String> parseCqrsResultTypes(Iterable<File> files) {
  final map = <String, String>{};
  for (final file in files) {
    final text = file.readAsStringSync();
    for (final decl in RegExp(
      r'(?:class|mixin)\s+([A-Za-z][A-Za-z0-9_]*)',
    ).allMatches(text)) {
      final symbol = decl.group(1)!;
      final endBrace = text.indexOf('{', decl.start);
      final endSemi = text.indexOf(';', decl.start);
      var end = -1;
      if (endBrace >= 0 && endSemi >= 0) {
        end = endBrace < endSemi ? endBrace : endSemi;
      } else {
        end = endBrace >= 0 ? endBrace : endSemi;
      }
      if (end < 0) continue;
      final signature = text.substring(decl.start, end);
      final target = RegExp(
        r'(?:I(?:Command|Query)|(?:Internal)?CommandBase|QueryBase)\s*<',
      ).firstMatch(signature);
      if (target == null) continue;
      final lessIndex = signature.indexOf('<', target.start);
      final type = _readBalancedGeneric(signature, lessIndex);
      if (type != null) {
        map[symbol] = normalizeType(type);
      }
    }
  }
  return map;
}

String normalizeType(String source) {
  return source.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String scenarioMember(String id) {
  final parts = id.split('_');
  if (parts.isEmpty) return id;
  return parts.first +
      parts.skip(1).map((part) {
        if (part.isEmpty) return '';
        return part[0].toUpperCase() + part.substring(1);
      }).join();
}

void _validateExportAndResultTypes({
  required String theme,
  required Map<String, List<ContractSymbolRow>> rowsBySlice,
  required Map<String, String> resultTypes,
  required List<ContractSemanticIssue> issues,
}) {
  for (final entry in rowsBySlice.entries) {
    final slice = entry.key;
    for (final row in entry.value) {
      final actual = resultTypes[row.symbol];
      if (actual == null) {
        issues.add(
          ContractSemanticIssue(
            theme: theme,
            slice: slice,
            rule: 'missing_public_export',
            detail: 'symbol=${row.symbol}',
          ),
        );
        continue;
      }
      if (row.successType == null) {
        issues.add(
          ContractSemanticIssue(
            theme: theme,
            slice: slice,
            rule: 'missing_result_type',
            detail: 'symbol=${row.symbol}',
          ),
        );
        continue;
      }
      final expected = normalizeType(row.successType!);
      if (expected != actual) {
        issues.add(
          ContractSemanticIssue(
            theme: theme,
            slice: slice,
            rule: 'result_type_mismatch',
            detail: 'symbol=${row.symbol} expected=$expected actual=$actual',
          ),
        );
      }
    }
  }
}

void _validateCmdCatalog({
  required String theme,
  required Map<String, List<ContractSymbolRow>> rowsBySlice,
  required Map<String, String> cmdCatalog,
  required List<ContractSemanticIssue> issues,
}) {
  final excluded = {
    'SignInTenantUserCommand',
    'SignInPlatformAdminCommand',
    'GetCurrentSessionQuery',
    'SendEmailDeliveryCommand',
  };
  final symbolToIds = <String, List<String>>{};
  final idToSymbols = <String, Set<String>>{};
  cmdCatalog.forEach((id, symbol) {
    symbolToIds.putIfAbsent(symbol, () => []).add(id);
    idToSymbols.putIfAbsent(id, () => <String>{}).add(symbol);
  });

  for (final entry in rowsBySlice.entries) {
    final slice = entry.key;
    for (final row in entry.value) {
      if (excluded.contains(row.symbol)) continue;
      final ids = symbolToIds[row.symbol] ?? const <String>[];
      if (ids.isEmpty) {
        issues.add(
          ContractSemanticIssue(
            theme: theme,
            slice: slice,
            rule: 'missing_cmd_catalog_symbol',
            detail: 'symbol=${row.symbol}',
          ),
        );
      } else if (ids.length > 1) {
        issues.add(
          ContractSemanticIssue(
            theme: theme,
            slice: slice,
            rule: 'duplicate_cmd_catalog_symbol',
            detail: 'symbol=${row.symbol} ids=${ids.join(",")}',
          ),
        );
      }
    }
  }

  for (final entry in idToSymbols.entries) {
    if (entry.value.length > 1) {
      issues.add(
        ContractSemanticIssue(
          theme: theme,
          slice: '-',
          rule: 'duplicate_cmd_catalog_id',
          detail: 'id=${entry.key} symbols=${entry.value.join(",")}',
        ),
      );
    }
  }
}

void _validateScenarios({
  required String theme,
  required Map<String, List<ScenarioRow>> rowsBySlice,
  required Set<String> iamScenarioMembers,
  required Set<String> notifyScenarioMembers,
  required Set<String> scenarioRefs,
  required List<ContractSemanticIssue> issues,
}) {
  final memberToIds = <String, Set<String>>{};
  final idToRows = <String, List<(String, ScenarioRow)>>{};

  for (final entry in rowsBySlice.entries) {
    final slice = entry.key;
    final enumName = slice == 'S-NOTIFY'
        ? 'FakeEmailDeliveryScenario'
        : 'FakeIamScenario';
    final enumMembers = slice == 'S-NOTIFY'
        ? notifyScenarioMembers
        : iamScenarioMembers;
    for (final row in entry.value) {
      final member = scenarioMember(row.id);
      memberToIds
          .putIfAbsent('$enumName.$member', () => <String>{})
          .add(row.id);
      idToRows.putIfAbsent(row.id, () => <(String, ScenarioRow)>[]).add((
        slice,
        row,
      ));

      if (!enumMembers.contains(member)) {
        issues.add(
          ContractSemanticIssue(
            theme: theme,
            slice: slice,
            rule: 'missing_fake_scenario',
            detail: 'scenario_id=${row.id} member=$enumName.$member',
          ),
        );
      }

      if (!scenarioRefs.contains('$enumName.$member')) {
        issues.add(
          ContractSemanticIssue(
            theme: theme,
            slice: slice,
            rule: 'untested_fake_scenario',
            detail: 'scenario_id=${row.id} member=$enumName.$member',
          ),
        );
      }
    }
  }

  for (final entry in memberToIds.entries) {
    if (entry.value.length > 1) {
      issues.add(
        ContractSemanticIssue(
          theme: theme,
          slice: '-',
          rule: 'duplicate_fake_scenario_mapping',
          detail: 'member=${entry.key} scenario_ids=${entry.value.join(",")}',
        ),
      );
    }
  }

  for (final entry in idToRows.entries) {
    if (entry.value.length < 2) continue;
    final slices = entry.value.map((e) => e.$1).toSet();
    final responses = entry.value.map((e) => e.$2.response).toSet();
    final allowedDuplicate =
        slices.length == 2 && slices.contains('S0') && slices.contains('S14');
    if ((!allowedDuplicate && slices.length > 1) || responses.length > 1) {
      issues.add(
        ContractSemanticIssue(
          theme: theme,
          slice: '-',
          rule: 'conflicting_duplicate_scenario',
          detail: 'scenario_id=${entry.key} slices=${slices.join(",")}',
        ),
      );
    }
  }
}

Set<String> _parseEnumMembers(File file, String enumName) {
  if (!file.existsSync()) return {};
  final text = file.readAsStringSync();
  final enumStart = RegExp('enum\\s+$enumName\\s*\\{').firstMatch(text);
  if (enumStart == null) return {};
  final open = text.indexOf('{', enumStart.start);
  final close = text.indexOf('}', open + 1);
  if (open < 0 || close < 0) return {};
  final body = text.substring(open + 1, close);
  final members = <String>{};
  for (final rawLine in body.split('\n')) {
    final withoutComment = rawLine.split('//').first.trim();
    if (withoutComment.isEmpty) continue;
    final m = RegExp(
      r'^([A-Za-z][A-Za-z0-9_]*)\s*,?$',
    ).firstMatch(withoutComment);
    if (m != null) {
      members.add(m.group(1)!);
    }
  }
  return members;
}

Set<String> _collectScenarioRefs(Directory testRoot) {
  final refs = <String>{};
  if (!testRoot.existsSync()) return refs;
  for (final entity in testRoot.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('_test.dart')) continue;
    final text = entity.readAsStringSync();
    for (final m in RegExp(
      r'FakeIamScenario\.([A-Za-z][A-Za-z0-9_]*)',
    ).allMatches(text)) {
      refs.add('FakeIamScenario.${m.group(1)!}');
    }
    for (final m in RegExp(
      r'FakeEmailDeliveryScenario\.([A-Za-z][A-Za-z0-9_]*)',
    ).allMatches(text)) {
      refs.add('FakeEmailDeliveryScenario.${m.group(1)!}');
    }
  }
  return refs;
}

String? _firstBackticked(String text) {
  final m = RegExp(r'`([^`]+)`').firstMatch(text);
  return m?.group(1);
}

String? _readBalancedGeneric(String source, int lessThanIndex) {
  if (lessThanIndex < 0 ||
      lessThanIndex >= source.length ||
      source[lessThanIndex] != '<') {
    return null;
  }
  var depth = 0;
  final buffer = StringBuffer();
  for (var i = lessThanIndex + 1; i < source.length; i++) {
    final ch = source[i];
    if (ch == '<') {
      depth++;
      buffer.write(ch);
      continue;
    }
    if (ch == '>') {
      if (depth == 0) {
        return buffer.toString();
      }
      depth--;
      buffer.write(ch);
      continue;
    }
    buffer.write(ch);
  }
  return null;
}

String _normalizeScenarioResponse(String source) {
  return source.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
