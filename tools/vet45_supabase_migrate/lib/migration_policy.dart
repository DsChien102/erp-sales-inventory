import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'migration_header.dart';
import 'migration_registry.dart';
import 'schema_lock.dart';
import 'sql_function_extractor.dart';
import 'sql_object_parser.dart';
import 'sql_object_render.dart';
import 'sql_source_discovery.dart';

enum PolicySeverity { error, warning }

class PolicyViolation {
  const PolicyViolation({
    required this.file,
    required this.code,
    required this.message,
    this.severity = PolicySeverity.error,
  });

  final String file;
  final String code;
  final String message;
  final PolicySeverity severity;
}

class MigrationPolicyOptions {
  const MigrationPolicyOptions({
    this.strict = false,
    this.registryPath,
    this.schemaLock,
    this.repoRoot,
  });

  final bool strict;
  final String? registryPath;

  /// Adopted declarative objects. When null, adopted-object guards are skipped.
  final SchemaLock? schemaLock;

  /// Repo root for reading declarative sources (generated region byte-match).
  final Directory? repoRoot;
}

class MigrationPolicyVerifier {
  static const patchFunctionCap = 8;
  static const surgicalFunctionCap = 3;

  List<PolicyViolation> verifyDirectory({
    required Directory migrationsDirectory,
    MigrationRegistry? registry,
    MigrationPolicyOptions options = const MigrationPolicyOptions(),
  }) {
    final loadedRegistry = registry ??
        MigrationRegistry.load(
          File(
            options.registryPath ??
                '${migrationsDirectory.path}/REGISTRY.yaml',
          ),
        );

    final violations = <PolicyViolation>[];
    final files = migrationsDirectory
        .listSync()
        .whereType<File>()
        .where((file) => RegExp(r'^\d{11,14}_').hasMatch(_basename(file.path)))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final name = _basename(file.path);
      final sql = file.readAsStringSync();
      violations.addAll(
        verifyFile(
          fileName: name,
          sql: sql,
          registry: loadedRegistry,
          options: options,
        ),
      );
    }

    return violations;
  }

  List<PolicyViolation> verifyFile({
    required String fileName,
    required String sql,
    required MigrationRegistry registry,
    MigrationPolicyOptions options = const MigrationPolicyOptions(),
  }) {
    if (registry.isGrandfathered(fileName)) {
      return const [];
    }

    final header = MigrationHeader.parse(sql);
    final body = stripHeaderComments(sql);
    final functionsInBody = extractFunctionNamesFromSql(body);
    final violations = <PolicyViolation>[];

    if (!header.hasKind) {
      violations.add(
        PolicyViolation(
          file: fileName,
          code: 'header_kind',
          message: 'Missing required -- Kind: header (bootstrap_grandfathered only skips strict checks).',
        ),
      );
      return violations;
    }

    if (!migrationKinds.contains(header.kind)) {
      violations.add(
        PolicyViolation(
          file: fileName,
          code: 'header_kind',
          message: 'Unknown Kind "${header.kind}". Expected: ${migrationKinds.join(", ")}.',
        ),
      );
    }

    final requiresIntent = header.kind == 'patch' ||
        header.kind == 'surgical' ||
        header.kind == 'generated';
    if (requiresIntent && (header.intent == null || header.intent!.isEmpty)) {
      violations.add(
        PolicyViolation(
          file: fileName,
          code: 'header_intent',
          message: 'Kind ${header.kind} requires -- Intent: header.',
        ),
      );
    }

    if (header.kind == 'generated') {
      violations.addAll(
        _verifyTouchesMatchBody(
          fileName: fileName,
          header: header,
          functionsInBody: extractFunctionsFromSql(body),
        ),
      );
      violations.addAll(
        _verifyGeneratedRegionsMatchSources(
          fileName: fileName,
          sql: sql,
          schemaLock: options.schemaLock,
          repoRoot: options.repoRoot,
        ),
      );
    }

    if (header.kind == 'patch' || header.kind == 'surgical') {

      violations.addAll(
        _verifyTouchesMatchBody(
          fileName: fileName,
          header: header,
          functionsInBody: functionsInBody,
        ),
      );

      violations.addAll(
        _verifyFunctionCap(
          fileName: fileName,
          kind: header.kind!,
          functionCount: functionsInBody.length,
        ),
      );

      violations.addAll(
        _verifyRegistryConsistency(
          fileName: fileName,
          header: header,
          functionsInBody: functionsInBody,
          registry: registry,
        ),
      );

      violations.addAll(
        _verifyNoUntouchedRpc(
          fileName: fileName,
          header: header,
          functionsInBody: functionsInBody,
          registry: registry,
        ),
      );
    }

    if (header.kind != 'generated') {
      violations.addAll(
        _verifyNoAdoptedObjectBypass(
          fileName: fileName,
          sql: body,
          kind: header.kind,
          schemaLock: options.schemaLock,
        ),
      );
    }

    return violations;
  }

  List<PolicyViolation> _verifyNoAdoptedObjectBypass({
    required String fileName,
    required String sql,
    required String? kind,
    required SchemaLock? schemaLock,
  }) {
    if (schemaLock == null || schemaLock.entries.isEmpty) {
      return const [];
    }

    final violations = <PolicyViolation>[];
    for (final object in parseSqlObjects(sql)) {
      if (!schemaLock.entries.containsKey(object.qualifiedName)) {
        continue;
      }
      violations.add(
        PolicyViolation(
          file: fileName,
          code: 'adopted_object_bypass',
          message:
              '${object.qualifiedName} is adopted in schema.lock.yaml; '
              'edit the declarative source and run migrate:generate '
              '(Kind ${kind ?? "unknown"} migrations must not recreate it).',
        ),
      );
    }
    return violations;
  }

  /// Byte-matches generated object regions to declarative sources at lock hash.
  ///
  /// Only checks objects whose `last_migration` is [fileName]. Regions `pre` /
  /// `post` are ignored so they stay hand-editable.
  List<PolicyViolation> _verifyGeneratedRegionsMatchSources({
    required String fileName,
    required String sql,
    required SchemaLock? schemaLock,
    required Directory? repoRoot,
  }) {
    if (schemaLock == null || repoRoot == null) {
      return const [];
    }

    final owned = schemaLock.entries.entries
        .where((entry) => entry.value.lastMigration == fileName)
        .toList();
    if (owned.isEmpty) {
      return const [];
    }

    final regions = extractMigrationRegions(sql);
    final violations = <PolicyViolation>[];

    for (final MapEntry(key: qualifiedName, value: entry) in owned) {
      final sourceFile = File('${repoRoot.path}/${entry.sourcePath}');
      if (!sourceFile.existsSync()) {
        violations.add(
          PolicyViolation(
            file: fileName,
            code: 'generated_region_mismatch',
            message:
                '$qualifiedName: source ${entry.sourcePath} missing for lock hash check.',
          ),
        );
        continue;
      }

      final content = sourceFile.readAsStringSync().replaceAll('\r\n', '\n');
      final hash = 'sha256:${sha256.convert(utf8.encode(content))}';
      if (hash != entry.hash) {
        violations.add(
          PolicyViolation(
            file: fileName,
            code: 'generated_region_mismatch',
            message:
                '$qualifiedName: source hash differs from schema.lock.yaml '
                '(run migrate:generate).',
          ),
        );
        continue;
      }

      final objects = parseSqlObjects(content);
      if (objects.isEmpty) {
        violations.add(
          PolicyViolation(
            file: fileName,
            code: 'generated_region_mismatch',
            message: '$qualifiedName: source has no create statement.',
          ),
        );
        continue;
      }

      final kind = objects.first.kind;
      final regionName = regionNameForKind(kind);
      final regionBody = regions[regionName] ?? '';
      final expected = renderDeclarativeSource(
        SqlSource(
          kind: kind,
          relativePath: entry.sourcePath,
          qualifiedName: qualifiedName,
          content: content,
          hash: hash,
          signatures: entry.signatures,
        ),
      );

      if (!_regionContainsExactSourceBlock(regionBody, expected)) {
        violations.add(
          PolicyViolation(
            file: fileName,
            code: 'generated_region_mismatch',
            message:
                '$qualifiedName: region `$regionName` does not byte-match '
                'declarative source at lock hash (do not hand-edit generated regions).',
          ),
        );
      }
    }

    // Extra non-drop SQL in generated regions (beyond locked sources) is a hand-edit.
    for (final regionName in generatedObjectRegionNames) {
      final regionBody = regions[regionName];
      if (regionBody == null || regionBody.isEmpty) {
        continue;
      }
      var remaining = regionBody;
      for (final MapEntry(key: _, value: entry) in owned) {
        final sourceFile = File('${repoRoot.path}/${entry.sourcePath}');
        if (!sourceFile.existsSync()) {
          continue;
        }
        final content = sourceFile.readAsStringSync().replaceAll('\r\n', '\n');
        final objects = parseSqlObjects(content);
        if (objects.isEmpty) {
          continue;
        }
        if (regionNameForKind(objects.first.kind) != regionName) {
          continue;
        }
        final expected = renderDeclarativeSource(
          SqlSource(
            kind: objects.first.kind,
            relativePath: entry.sourcePath,
            qualifiedName: objects.first.qualifiedName,
            content: content,
            hash: entry.hash,
            signatures: entry.signatures,
          ),
        );
        remaining = remaining.replaceFirst(expected, '');
      }
      final leftover = _stripDropStatements(remaining).trim();
      if (leftover.isNotEmpty) {
        violations.add(
          PolicyViolation(
            file: fileName,
            code: 'generated_region_mismatch',
            message:
                'region `$regionName` has hand-edited SQL beyond declarative '
                'sources for this migration.',
          ),
        );
      }
    }

    return violations;
  }

  /// True when [expected] appears as an exact contiguous block in [regionBody].
  bool _regionContainsExactSourceBlock(String regionBody, String expected) {
    return regionBody.contains(expected);
  }

  /// Removes `drop … if exists …;` lines left by signature/file replacement.
  String _stripDropStatements(String sql) {
    final pattern = RegExp(
      r'^\s*drop\s+(function|view|trigger|policy)\s+if\s+exists\b[^;]*;',
      caseSensitive: false,
      multiLine: true,
    );
    return sql.replaceAll(pattern, '');
  }

  List<PolicyViolation> _verifyTouchesMatchBody({
    required String fileName,
    required MigrationHeader header,
    required List<String> functionsInBody,
  }) {
    final violations = <PolicyViolation>[];
    final touches = header.touches.toSet();
    final bodySet = functionsInBody.toSet();

    if (touches.isEmpty && bodySet.isNotEmpty) {
      violations.add(
        PolicyViolation(
          file: fileName,
          code: 'touches_match_body',
          message:
              'Body defines ${bodySet.join(", ")} but -- Touches: is empty.',
        ),
      );
      return violations;
    }

    final notInTouches = bodySet.difference(touches);
    if (notInTouches.isNotEmpty) {
      violations.add(
        PolicyViolation(
          file: fileName,
          code: 'touches_match_body',
          message:
              'CREATE FUNCTION in body not listed in Touches: ${notInTouches.join(", ")}.',
        ),
      );
    }

    final notInBody = touches.difference(bodySet);
    if (notInBody.isNotEmpty) {
      violations.add(
        PolicyViolation(
          file: fileName,
          code: 'touches_match_body',
          message:
              'Touches lists functions not defined in body: ${notInBody.join(", ")}.',
        ),
      );
    }

    return violations;
  }

  List<PolicyViolation> _verifyFunctionCap({
    required String fileName,
    required String kind,
    required int functionCount,
  }) {
    final cap = kind == 'surgical' ? surgicalFunctionCap : patchFunctionCap;
    if (functionCount > cap) {
      return [
        PolicyViolation(
          file: fileName,
          code: 'patch_function_cap',
          message:
              'Kind $kind allows at most $cap functions; found $functionCount.',
        ),
      ];
    }
    return const [];
  }

  List<PolicyViolation> _verifyRegistryConsistency({
    required String fileName,
    required MigrationHeader header,
    required List<String> functionsInBody,
    required MigrationRegistry registry,
  }) {
    final violations = <PolicyViolation>[];
    final schema = _inferSchema(fileName, header);

    for (final functionName in functionsInBody) {
      final owner = registry.ownerMigration(
        schema: schema,
        functionName: functionName,
      );
      if (owner == null) {
        violations.add(
          PolicyViolation(
            file: fileName,
            code: 'registry_consistency',
            message:
                '$schema.$functionName not found in REGISTRY.yaml (add owner after promote).',
            severity: PolicySeverity.warning,
          ),
        );
      }
    }

    return violations;
  }

  List<PolicyViolation> _verifyNoUntouchedRpc({
    required String fileName,
    required MigrationHeader header,
    required List<String> functionsInBody,
    required MigrationRegistry registry,
  }) {
    final violations = <PolicyViolation>[];
    final schema = _inferSchema(fileName, header);
    final dependsOn = header.dependsOn.toSet();

    for (final functionName in functionsInBody) {
      final owner = registry.ownerMigration(
        schema: schema,
        functionName: functionName,
      );
      if (owner == null || owner == fileName) {
        continue;
      }

      final ownerBase = owner.replaceAll('.sql', '');
      final dependsIncludesOwner = dependsOn.any(
        (dep) => dep.contains(ownerBase) || owner.contains(dep.replaceAll('.sql', '')),
      );

      if (!dependsIncludesOwner) {
        violations.add(
          PolicyViolation(
            file: fileName,
            code: 'no_untouched_rpc',
            message:
                '$schema.$functionName owned by $owner but not listed in Depends on.',
            severity: PolicySeverity.warning,
          ),
        );
      }
    }

    return violations;
  }

  String _inferSchema(String fileName, MigrationHeader header) {
    if (fileName.contains('_catalog_')) {
      return 'catalog';
    }
    if (fileName.contains('_iam_')) {
      return 'iam';
    }
    if (fileName.contains('_platform_')) {
      return 'platform';
    }
    if (header.intent != null && header.intent!.startsWith('catalog_')) {
      return 'catalog';
    }
    return 'catalog';
  }

  String _basename(String path) => path.split(Platform.pathSeparator).last;
}
