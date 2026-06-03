/// Clones payload and injects row [id] for [json_serializable] deserialization only.
///
/// The row `id` is stored in `internal_commands.id`, not persisted in payload.
Map<String, dynamic> normalizeInternalCommandDeserializeJson(
  Map<String, dynamic> json, {
  required String rowId,
}) {
  final map = Map<String, dynamic>.from(json);
  map['id'] = rowId;
  return map;
}

/// Removes row `id` from a payload map if present (defensive inbound cleanup).
Map<String, dynamic> stripInternalCommandRowId(Map<String, dynamic> json) {
  final map = Map<String, dynamic>.from(json);
  map.remove('id');
  return map;
}
