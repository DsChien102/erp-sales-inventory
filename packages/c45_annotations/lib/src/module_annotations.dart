/// Module-level metadata for codegen manifests and architecture checks.
class ModuleManifest {
  const ModuleManifest({
    required this.name,
    this.permissions = const [],
    this.version,
  });

  final String name;
  final List<String> permissions;
  final String? version;
}
