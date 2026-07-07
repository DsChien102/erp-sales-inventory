import 'package:async_query/async_query.dart';
import 'package:flutter/widgets.dart';

import 'query_client_provider.dart';

/// Refetches active queries when the app returns to foreground.
class AppLifecycleRefetch extends StatefulWidget {
  const AppLifecycleRefetch({
    required this.child,
    this.client,
    this.queryKey,
    super.key,
  });

  final Widget child;
  final QueryClient? client;
  final QueryKeyFilter? queryKey;

  @override
  State<AppLifecycleRefetch> createState() => _AppLifecycleRefetchState();
}

class _AppLifecycleRefetchState extends State<AppLifecycleRefetch>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final client = widget.client ?? QueryClientProvider.maybeOf(context);
      client?.refetchQueries(queryKey: widget.queryKey);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
