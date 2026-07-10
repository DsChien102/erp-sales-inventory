import 'dart:io';

import 'migration_registry.dart';
import 'sql_function_extractor.dart';

class SeedRegistryResult {
  const SeedRegistryResult({
    required this.registry,
    required this.scannedFiles,
    required this.functionCount,
  });

  final MigrationRegistry registry;
  final int scannedFiles;
  final int functionCount;
}

class SeedRegistryService {
  static final _migrationFilePattern = RegExp(r'^\d{11,14}_');

  SeedRegistryResult seed({
    required Directory migrationsDirectory,
    List<String> catalogGrandfathered = const [],
  }) {
    final registry = MigrationRegistry.empty();
    final files = migrationsDirectory
        .listSync()
        .whereType<File>()
        .where((file) => _migrationFilePattern.hasMatch(_basename(file.path)))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final sql = file.readAsStringSync();
      final migrationName = _basename(file.path);
      for (final qualified in extractFunctionsFromSql(sql)) {
        final parts = qualified.split('.');
        if (parts.length != 2) {
          continue;
        }
        registry.setOwner(
          schema: parts[0],
          functionName: parts[1],
          migrationFile: migrationName,
        );
      }
    }

    final grandfathered = catalogGrandfathered.isNotEmpty
        ? List<String>.from(catalogGrandfathered)
        : files.map((file) => _basename(file.path)).toList();

    final functionCount = registry.schemas.values.fold<int>(
      0,
      (sum, map) => sum + map.length,
    );

    return SeedRegistryResult(
      registry: MigrationRegistry(
        schemas: registry.schemas,
        bootstrapGrandfathered: grandfathered,
        phase2Notes: const [
          'Phase 2 pilot: split _drafts/catalog_product_sku_barcode_inline_normalize.sql',
          '  into 001_catalog_patch_sku_barcode_schema.sql + 002_catalog_patch_sku_barcode_rpcs.sql',
          '  then promote with: melos run migrate:promote-drafts -- --write --bundle-intent',
        ],
      ),
      scannedFiles: files.length,
      functionCount: functionCount,
    );
  }

  String _basename(String path) => path.split(Platform.pathSeparator).last;
}
