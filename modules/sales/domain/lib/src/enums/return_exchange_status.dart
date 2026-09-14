enum ReturnExchangeStatus {
  /// Technical recovery only — not a user-managed draft list item (Phase 1).
  draft,
  confirmed,
  processing,
  completed,
  cancelled,
  blocked,
  failed,
}
