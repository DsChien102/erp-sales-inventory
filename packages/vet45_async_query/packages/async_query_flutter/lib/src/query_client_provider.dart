import 'package:async_query/async_query.dart';
import 'package:flutter/widgets.dart';

/// Provides a [QueryClient] to the widget subtree.
class QueryClientProvider extends InheritedWidget {
  const QueryClientProvider({
    required this.client,
    required super.child,
    super.key,
  });

  final QueryClient client;

  static QueryClient of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<QueryClientProvider>();
    assert(provider != null, 'QueryClientProvider not found in context');
    return provider!.client;
  }

  static QueryClient? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<QueryClientProvider>()
        ?.client;
  }

  @override
  bool updateShouldNotify(QueryClientProvider oldWidget) {
    return !identical(client, oldWidget.client);
  }
}
