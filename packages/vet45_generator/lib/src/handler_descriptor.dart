final class ConstructorDependency {
  const ConstructorDependency({
    required this.name,
    required this.typeName,
  });

  final String name;
  final String typeName;
}

enum HandlerKind {
  business,
  internal,
  query,
  validator,
}

final class HandlerDescriptor {
  const HandlerDescriptor({
    required this.kind,
    required this.className,
    required this.commandTypeName,
    this.resultTypeName,
    this.queryTypeName,
    this.dependencies = const [],
  });

  final HandlerKind kind;
  final String className;
  final String commandTypeName;
  final String? resultTypeName;
  final String? queryTypeName;
  final List<ConstructorDependency> dependencies;

  String get sortKey => className;
}
