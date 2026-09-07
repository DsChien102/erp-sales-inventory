import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_einvoice_domain/domain.dart';

import '../bloc/order_einvoice_cubit.dart';
import '../bloc/order_einvoice_state.dart';

/// Polls pending work while this section is visible, including below a sheet.
class OrderEInvoicePollingHost extends StatefulWidget {
  const OrderEInvoicePollingHost({super.key, required this.child});

  final Widget child;

  @override
  State<OrderEInvoicePollingHost> createState() => _OrderEInvoicePollingHostState();
}

class _OrderEInvoicePollingHostState extends State<OrderEInvoicePollingHost>
    with WidgetsBindingObserver {
  Timer? _timer;
  StreamSubscription<OrderEInvoiceState>? _subscription;
  OrderEInvoiceCubit? _cubit;
  bool _visible = true;
  bool _foreground = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cubit = context.read<OrderEInvoiceCubit>();
    if (_cubit != cubit) {
      _subscription?.cancel();
      _cubit = cubit;
      _subscription = cubit.stream.listen((_) => _schedule());
    }
    // Opaque routes disable tickers below them; popup sheets keep them active.
    _visible = TickerMode.of(context);
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _schedule();
  }

  void _schedule() {
    final cubit = _cubit;
    if (cubit == null || cubit.isClosed) return;
    final state = cubit.state;
    final pending =
        state.projection.deliveryPending ||
        state.projection.issuanceDisplayState == IssuanceDisplayState.processing ||
        state.projection.deliveryDisplayState == DeliveryDisplayState.sending;
    if (!_visible || !_foreground || !state.isPageActive || !pending) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_refreshing || cubit.isClosed) return;
      _refreshing = true;
      try {
        await cubit.refresh();
      } finally {
        _refreshing = false;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
