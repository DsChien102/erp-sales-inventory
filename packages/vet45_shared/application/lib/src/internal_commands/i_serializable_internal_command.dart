abstract interface class ISerializableInternalCommand {
  String get commandType;

  String get tenantId;

  Map<String, dynamic> toJson();
}
