abstract interface class IDomainNotificationMapper {
  String? getName(Type type);
  Type? getType(String name);
}
