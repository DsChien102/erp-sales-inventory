/// Optional honorific for person partners — wraps free-form user text (not enum-normalized).
///
/// So sánh bằng theo [value], giống bản `ValueObject` cũ.
final class PersonTitle {
  PersonTitle(String raw) : value = raw {
    if (raw.trim().isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'Person title must not be blank');
    }
  }

  final String value;

  @override
  bool operator ==(Object other) => other is PersonTitle && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
