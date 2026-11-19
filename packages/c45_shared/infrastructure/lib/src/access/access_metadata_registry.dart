import 'package:c45_shared_application/application.dart';

/// Runtime registry of access metadata generated per module.
final class AccessMetadataRegistry implements IAccessMetadataRegistry {
  AccessMetadataRegistry(this._entries);

  final Map<Type, AccessMetadata> _entries;

  @override
  AccessMetadata? forType(Type messageType) => _entries[messageType];
}
