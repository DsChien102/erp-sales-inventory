/// Sort order for product list search (EPIC-01/US-01).
enum ProductSortOrder {
  updatedAtDesc,

  /// FTS relevance rank — meaningful when [ProductSearchCriteria.keyword] is set.
  /// Inactive products remain pinned after active (server-side).
  relevanceDesc,
}
