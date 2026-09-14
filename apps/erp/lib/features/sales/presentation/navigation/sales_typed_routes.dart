import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_sales_application/application.dart';

import '../models/sales_order/sales_checkout_draft_args.dart';
import '../models/sales_order/sales_checkout_result_args.dart';
import '../orchestration/sales_draft_list_scope.dart';
import '../pages/sales_checkout_invalid_entry_page.dart';
import '../pages/sales_checkout_page.dart';
import '../pages/sales_draft_list_page.dart';
import '../pages/sales_order_compose_page.dart';
import '../pages/sales_order_detail_page.dart';
import '../pages/sales_order_slip_preview_page.dart';
import '../pages/sales_result_invalid_entry_page.dart';
import '../pages/sales_return_exchange_create_page.dart';
import '../pages/sales_return_exchange_detail_page.dart';
import '../pages/sales_return_exchange_result_page.dart';
import '../pages/sales_return_exchange_settlement_page.dart';
import '../pages/sales_return_exchange_slip_preview_page.dart';
import '../pages/sales_transaction_result_page.dart';

part 'sales_typed_routes.g.dart';

/// Dashboard tab orders list — not part of typed sales `$appRoutes`.
abstract final class SalesNav {
  static const ordersList = '/orders';
  static const ordersListName = 'orders.list';

  /// Match order-detail on the stack for `Navigator.popUntil`.
  static bool isOrderDetailRoute(Route<dynamic> route, String orderId) {
    final name = route.settings.name;
    return name == 'sales.orders.detail' ||
        name == SalesOrderDetailRoute(orderId: orderId).location;
  }
}

// ---------------------------------------------------------------------------
// Shell: shared SalesDraftListCubit for drafts + compose
// ---------------------------------------------------------------------------

@TypedShellRoute<SalesDraftShellRoute>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<SalesDraftsRoute>(
      path: '/sales/drafts',
      name: 'sales.drafts',
    ),
    TypedGoRoute<SalesComposeRoute>(
      path: '/sales/compose',
      name: 'sales.compose',
    ),
  ],
)
class SalesDraftShellRoute extends ShellRouteData {
  const SalesDraftShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return SalesDraftListScope(child: navigator);
  }
}

class SalesDraftsRoute extends GoRouteData with $SalesDraftsRoute {
  const SalesDraftsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SalesDraftListPage();
  }
}

class SalesComposeRoute extends GoRouteData with $SalesComposeRoute {
  const SalesComposeRoute({
    @TypedQueryParameter(name: 'draftId') this.draftId,
  });

  final String? draftId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SalesOrderComposePage(draftId: draftId);
  }
}

// ---------------------------------------------------------------------------
// Top-level sales routes
// ---------------------------------------------------------------------------

@TypedGoRoute<SalesCheckoutRoute>(
  path: '/sales/checkout',
  name: 'sales.checkout',
)
class SalesCheckoutRoute extends GoRouteData with $SalesCheckoutRoute {
  const SalesCheckoutRoute({this.$extra});

  final SalesCheckoutDraftArgs? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final args = $extra;
    if (args == null) {
      return const SalesCheckoutInvalidEntryPage();
    }
    return SalesCheckoutPage(args: args);
  }
}

@TypedGoRoute<SalesResultRoute>(
  path: '/sales/result/:orderId',
  name: 'sales.result',
)
class SalesResultRoute extends GoRouteData with $SalesResultRoute {
  const SalesResultRoute({required this.orderId, this.$extra});

  final String orderId;
  final SalesCheckoutResultArgs? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final args = $extra;
    if (args == null || args.result.salesOrderId != orderId) {
      return const SalesResultInvalidEntryPage();
    }
    return SalesTransactionResultPage(args: args);
  }
}

@TypedGoRoute<SalesOrderDetailRoute>(
  path: '/sales/orders/:orderId',
  name: 'sales.orders.detail',
)
class SalesOrderDetailRoute extends GoRouteData with $SalesOrderDetailRoute {
  const SalesOrderDetailRoute({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SalesOrderDetailPage(orderId: orderId);
  }
}

@TypedGoRoute<SalesReturnNewRoute>(
  path: '/sales/orders/:orderId/returns/new',
  name: 'sales.orders.returns.new',
)
class SalesReturnNewRoute extends GoRouteData with $SalesReturnNewRoute {
  const SalesReturnNewRoute({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SalesReturnExchangeCreatePage(orderId: orderId);
  }
}

@TypedGoRoute<SalesReturnSettleRoute>(
  path: '/sales/orders/:orderId/returns/:returnExchangeId/settle',
  name: 'sales.orders.returns.settle',
)
class SalesReturnSettleRoute extends GoRouteData with $SalesReturnSettleRoute {
  const SalesReturnSettleRoute({
    required this.orderId,
    required this.returnExchangeId,
  });

  final String orderId;
  final String returnExchangeId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SalesReturnExchangeSettlementPage(
      orderId: orderId,
      returnExchangeId: returnExchangeId,
    );
  }
}

@TypedGoRoute<SalesReturnResultRoute>(
  path: '/sales/orders/:orderId/returns/:returnExchangeId/result',
  name: 'sales.orders.returns.result',
)
class SalesReturnResultRoute extends GoRouteData with $SalesReturnResultRoute {
  const SalesReturnResultRoute({
    required this.orderId,
    required this.returnExchangeId,
  });

  final String orderId;
  final String returnExchangeId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SalesReturnExchangeResultPage(
      orderId: orderId,
      returnExchangeId: returnExchangeId,
    );
  }
}

@TypedGoRoute<SalesReturnDetailRoute>(
  path: '/sales/orders/:orderId/returns/:returnExchangeId/detail',
  name: 'sales.orders.returns.detail',
)
class SalesReturnDetailRoute extends GoRouteData with $SalesReturnDetailRoute {
  const SalesReturnDetailRoute({
    required this.orderId,
    required this.returnExchangeId,
  });

  final String orderId;
  final String returnExchangeId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SalesReturnExchangeDetailPage(
      orderId: orderId,
      returnExchangeId: returnExchangeId,
    );
  }
}

@TypedGoRoute<SalesOrderPreviewRoute>(
  path: '/sales/orders/:orderId/preview',
  name: 'sales.orders.preview',
)
class SalesOrderPreviewRoute extends GoRouteData with $SalesOrderPreviewRoute {
  const SalesOrderPreviewRoute({required this.orderId, this.$extra});

  final String orderId;
  final SalesReceiptDto? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final receipt = $extra;
    if (receipt == null) {
      return SalesOrderSlipPreviewPage(orderId: orderId);
    }
    return SalesOrderSlipPreviewPage(orderId: orderId, receipt: receipt);
  }
}

@TypedGoRoute<SalesReturnPreviewRoute>(
  path: '/sales/orders/:orderId/returns/:returnExchangeId/preview',
  name: 'sales.orders.returns.preview',
)
class SalesReturnPreviewRoute extends GoRouteData with $SalesReturnPreviewRoute {
  const SalesReturnPreviewRoute({
    required this.orderId,
    required this.returnExchangeId,
  });

  final String orderId;
  final String returnExchangeId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SalesReturnExchangeSlipPreviewPage(
      orderId: orderId,
      returnExchangeId: returnExchangeId,
    );
  }
}
