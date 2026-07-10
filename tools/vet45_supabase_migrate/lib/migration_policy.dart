import 'dart:io';

import 'migration_header.dart';
import 'migration_registry.dart';
import 'sql_function_extractor.dart';

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
  });

  final bool strict;
  final String? registryPath;
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

    if (header.kind == 'patch' || header.kind == 'surgical') {
      if (header.intent == null || header.intent!.isEmpty) {
        violations.add(
          PolicyViolation(
            file: fileName,
            code: 'header_intent',
            message: 'Kind ${header.kind} requires -- Intent: header.',
          ),
        );
      }

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

    return violations;
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
