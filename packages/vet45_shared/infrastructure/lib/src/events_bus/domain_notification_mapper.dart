import 'package:quiver/collection.dart';

import 'i_domain_notification_mapper.dart';

class DomainNotificationMapper implements IDomainNotificationMapper {
  final BiMap<String, Type> _domainNotificationMap;

  DomainNotificationMapper(this._domainNotificationMap);

  @override
  String? getName(Type type) {
    return _domainNotificationMap.inverse[type];
  }

  @override
  Type? getType(String name) {
    return _domainNotificationMap[name];
  }
}
