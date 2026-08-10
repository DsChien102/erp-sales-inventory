/// Cursor-paginated page used by search/list contracts (S6+).
final class CursorPageDto<T> {
  const CursorPageDto({
    required this.items,
    this.nextCursor,
  });

  final List<T> items;
  final String? nextCursor;
}
