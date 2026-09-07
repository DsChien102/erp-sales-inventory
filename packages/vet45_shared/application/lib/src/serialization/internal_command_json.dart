/// Clones payload and injects row [id] for deserialization only.
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
  map.remove(internalCommandWorkerAttemptNumberKey);
  return map;
}

/// Reserved runtime key injected by the worker processor before deserialization.
const internalCommandWorkerAttemptNumberKey = '_worker_attempt_number';

/// Reads worker attempt number from deserialized payload (defaults to 1).
int readInternalCommandWorkerAttemptNumber(Map<String, dynamic> json) {
  final raw = json[internalCommandWorkerAttemptNumberKey];
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  return 1;
}
