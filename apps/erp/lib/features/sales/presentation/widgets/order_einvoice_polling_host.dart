import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/order_einvoice_cubit.dart';
import '../bloc/order_einvoice_state.dart';

/// Keeps invoice polling active while this section is visible, including below a sheet.
class OrderEInvoicePollingHost extends StatefulWidget {
  const OrderEInvoicePollingHost({super.key, required this.child});

  final Widget child;

  @override
  State<OrderEInvoicePollingHost> createState() => _OrderEInvoicePollingHostState();
}

class _OrderEInvoicePollingHostState extends State<OrderEInvoicePollingHost>
    with WidgetsBindingObserver {
  StreamSubscription<OrderEInvoiceState>? _subscription;
  OrderEInvoiceCubit? _cubit;
  bool _visible = true;
  bool _foreground = true;

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
      _subscription = cubit.stream.listen((_) => _syncPolling());
    }
    // Opaque routes disable tickers below them; popup sheets keep them active.
    _visible = TickerMode.valuesOf(context).enabled;
    _syncPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPolling();
  }

  void _syncPolling() {
    final cubit = _cubit;
    if (cubit == null || cubit.isClosed) return;
    final active = _visible && _foreground && cubit.state.isPageActive && cubit.state.shouldPoll;
    cubit.setPollingActive(active);
  }

  @override
  void dispose() {
    _cubit?.setPollingActive(false);
    _subscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
