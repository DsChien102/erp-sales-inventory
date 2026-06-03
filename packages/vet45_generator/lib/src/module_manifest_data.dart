final class ModuleManifestData {
  const ModuleManifestData({
    required this.className,
    required this.name,
    required this.permissions,
    this.version,
  });

  final String className;
  final String name;
  final List<String> permissions;
  final String? version;
}
