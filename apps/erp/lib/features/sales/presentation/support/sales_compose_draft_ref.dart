/// Sentinel and helpers for compose draft identity.
abstract final class SalesComposeDraftRef {
  static const String newDraft = 'draft-new';

  static bool isNew(String draftId) {
    final trimmed = draftId.trim();
    return trimmed.isEmpty || trimmed == newDraft;
  }

  static String? serverId(String draftId) => isNew(draftId) ? null : draftId.trim();
}
