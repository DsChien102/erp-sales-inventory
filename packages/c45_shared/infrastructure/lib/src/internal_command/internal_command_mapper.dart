import 'package:quiver/collection.dart';

abstract interface class IInternalCommandMapper {
  String? getName(Type type);
  Type? getType(String name);
}

class InternalCommandMapper implements IInternalCommandMapper {
  InternalCommandMapper({required BiMap<String, Type> internalCommandMap})
      : _internalCommandMap = internalCommandMap;

  final BiMap<String, Type> _internalCommandMap;

  @override
  String? getName(Type type) {
    return _internalCommandMap.inverse[type];
  }

  @override
  Type? getType(String name) {
    return _internalCommandMap[name];
  }
}
