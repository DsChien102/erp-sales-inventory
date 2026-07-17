final class CursorPageDto<T> {
  const CursorPageDto({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
}
