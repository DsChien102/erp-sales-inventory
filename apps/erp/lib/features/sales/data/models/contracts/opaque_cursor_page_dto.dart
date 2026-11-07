final class OpaqueCursorPageDto<T> {
  OpaqueCursorPageDto({
    required List<T> items,
    required this.hasMore,
    this.nextCursor,
  }) : items = List.unmodifiable(items);

  final List<T> items;
  final bool hasMore;
  final String? nextCursor;
}
