import 'query_key.dart';

/// Options for invalidating or refetching queries.
class InvalidateQueriesOptions {
  const InvalidateQueriesOptions({
    this.queryKey,
    this.exact = false,
    this.refetchType = RefetchType.active,
  });

  final QueryKeyFilter? queryKey;
  final bool exact;
  final RefetchType refetchType;
}

enum RefetchType {
  active,
  inactive,
  all,
  none,
}

class RefetchQueriesOptions {
  const RefetchQueriesOptions({
    this.queryKey,
    this.exact = false,
    this.type = RefetchType.active,
  });

  final QueryKeyFilter? queryKey;
  final bool exact;
  final RefetchType type;
}
