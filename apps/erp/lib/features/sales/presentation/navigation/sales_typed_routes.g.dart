// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_typed_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $salesDraftShellRoute,
  $salesCheckoutRoute,
  $salesResultRoute,
  $salesOrderDetailRoute,
  $salesReturnNewRoute,
  $salesReturnSettleRoute,
  $salesReturnResultRoute,
  $salesReturnDetailRoute,
  $salesOrderPreviewRoute,
  $salesReturnPreviewRoute,
];

RouteBase get $salesDraftShellRoute => ShellRouteData.$route(
  factory: $SalesDraftShellRouteExtension._fromState,
  routes: [
    GoRouteData.$route(
      path: '/sales/drafts',
      name: 'sales.drafts',
      hasOverriddenOnExit: false,
      factory: $SalesDraftsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/sales/compose',
      name: 'sales.compose',
      hasOverriddenOnExit: false,
      factory: $SalesComposeRoute._fromState,
    ),
  ],
);

extension $SalesDraftShellRouteExtension on SalesDraftShellRoute {
  static SalesDraftShellRoute _fromState(GoRouterState state) =>
      const SalesDraftShellRoute();
}

mixin $SalesDraftsRoute on GoRouteData {
  static SalesDraftsRoute _fromState(GoRouterState state) =>
      const SalesDraftsRoute();

  @override
  String get location => GoRouteData.$location('/sales/drafts');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SalesComposeRoute on GoRouteData {
  static SalesComposeRoute _fromState(GoRouterState state) =>
      SalesComposeRoute(draftId: state.uri.queryParameters['draftId']);

  SalesComposeRoute get _self => this as SalesComposeRoute;

  @override
  String get location => GoRouteData.$location(
    '/sales/compose',
    queryParams: {if (_self.draftId != null) 'draftId': _self.draftId},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $salesCheckoutRoute => GoRouteData.$route(
  path: '/sales/checkout',
  name: 'sales.checkout',
  hasOverriddenOnExit: false,
  factory: $SalesCheckoutRoute._fromState,
);

mixin $SalesCheckoutRoute on GoRouteData {
  static SalesCheckoutRoute _fromState(GoRouterState state) =>
      SalesCheckoutRoute($extra: state.extra as SalesCheckoutDraftArgs?);

  SalesCheckoutRoute get _self => this as SalesCheckoutRoute;

  @override
  String get location => GoRouteData.$location('/sales/checkout');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $salesResultRoute => GoRouteData.$route(
  path: '/sales/result/:orderId',
  name: 'sales.result',
  hasOverriddenOnExit: false,
  factory: $SalesResultRoute._fromState,
);

mixin $SalesResultRoute on GoRouteData {
  static SalesResultRoute _fromState(GoRouterState state) => SalesResultRoute(
    orderId: state.pathParameters['orderId']!,
    $extra: state.extra as SalesCheckoutResultArgs?,
  );

  SalesResultRoute get _self => this as SalesResultRoute;

  @override
  String get location => GoRouteData.$location(
    '/sales/result/${Uri.encodeComponent(_self.orderId)}',
  );

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $salesOrderDetailRoute => GoRouteData.$route(
  path: '/sales/orders/:orderId',
  name: 'sales.orders.detail',
  hasOverriddenOnExit: false,
  factory: $SalesOrderDetailRoute._fromState,
);

mixin $SalesOrderDetailRoute on GoRouteData {
  static SalesOrderDetailRoute _fromState(GoRouterState state) =>
      SalesOrderDetailRoute(orderId: state.pathParameters['orderId']!);

  SalesOrderDetailRoute get _self => this as SalesOrderDetailRoute;

  @override
  String get location => GoRouteData.$location(
    '/sales/orders/${Uri.encodeComponent(_self.orderId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $salesReturnNewRoute => GoRouteData.$route(
  path: '/sales/orders/:orderId/returns/new',
  name: 'sales.orders.returns.new',
  hasOverriddenOnExit: false,
  factory: $SalesReturnNewRoute._fromState,
);

mixin $SalesReturnNewRoute on GoRouteData {
  static SalesReturnNewRoute _fromState(GoRouterState state) =>
      SalesReturnNewRoute(orderId: state.pathParameters['orderId']!);

  SalesReturnNewRoute get _self => this as SalesReturnNewRoute;

  @override
  String get location => GoRouteData.$location(
    '/sales/orders/${Uri.encodeComponent(_self.orderId)}/returns/new',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $salesReturnSettleRoute => GoRouteData.$route(
  path: '/sales/orders/:orderId/returns/:returnExchangeId/settle',
  name: 'sales.orders.returns.settle',
  hasOverriddenOnExit: false,
  factory: $SalesReturnSettleRoute._fromState,
);

mixin $SalesReturnSettleRoute on GoRouteData {
  static SalesReturnSettleRoute _fromState(GoRouterState state) =>
      SalesReturnSettleRoute(
        orderId: state.pathParameters['orderId']!,
        returnExchangeId: state.pathParameters['returnExchangeId']!,
      );

  SalesReturnSettleRoute get _self => this as SalesReturnSettleRoute;

  @override
  String get location => GoRouteData.$location(
    '/sales/orders/${Uri.encodeComponent(_self.orderId)}/returns/${Uri.encodeComponent(_self.returnExchangeId)}/settle',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $salesReturnResultRoute => GoRouteData.$route(
  path: '/sales/orders/:orderId/returns/:returnExchangeId/result',
  name: 'sales.orders.returns.result',
  hasOverriddenOnExit: false,
  factory: $SalesReturnResultRoute._fromState,
);

mixin $SalesReturnResultRoute on GoRouteData {
  static SalesReturnResultRoute _fromState(GoRouterState state) =>
      SalesReturnResultRoute(
        orderId: state.pathParameters['orderId']!,
        returnExchangeId: state.pathParameters['returnExchangeId']!,
      );

  SalesReturnResultRoute get _self => this as SalesReturnResultRoute;

  @override
  String get location => GoRouteData.$location(
    '/sales/orders/${Uri.encodeComponent(_self.orderId)}/returns/${Uri.encodeComponent(_self.returnExchangeId)}/result',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $salesReturnDetailRoute => GoRouteData.$route(
  path: '/sales/orders/:orderId/returns/:returnExchangeId/detail',
  name: 'sales.orders.returns.detail',
  hasOverriddenOnExit: false,
  factory: $SalesReturnDetailRoute._fromState,
);

mixin $SalesReturnDetailRoute on GoRouteData {
  static SalesReturnDetailRoute _fromState(GoRouterState state) =>
      SalesReturnDetailRoute(
        orderId: state.pathParameters['orderId']!,
        returnExchangeId: state.pathParameters['returnExchangeId']!,
      );

  SalesReturnDetailRoute get _self => this as SalesReturnDetailRoute;

  @override
  String get location => GoRouteData.$location(
    '/sales/orders/${Uri.encodeComponent(_self.orderId)}/returns/${Uri.encodeComponent(_self.returnExchangeId)}/detail',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $salesOrderPreviewRoute => GoRouteData.$route(
  path: '/sales/orders/:orderId/preview',
  name: 'sales.orders.preview',
  hasOverriddenOnExit: false,
  factory: $SalesOrderPreviewRoute._fromState,
);

mixin $SalesOrderPreviewRoute on GoRouteData {
  static SalesOrderPreviewRoute _fromState(GoRouterState state) =>
      SalesOrderPreviewRoute(
        orderId: state.pathParameters['orderId']!,
        $extra: state.extra as SalesReceiptDto?,
      );

  SalesOrderPreviewRoute get _self => this as SalesOrderPreviewRoute;

  @override
  String get location => GoRouteData.$location(
    '/sales/orders/${Uri.encodeComponent(_self.orderId)}/preview',
  );

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $salesReturnPreviewRoute => GoRouteData.$route(
  path: '/sales/orders/:orderId/returns/:returnExchangeId/preview',
  name: 'sales.orders.returns.preview',
  hasOverriddenOnExit: false,
  factory: $SalesReturnPreviewRoute._fromState,
);

mixin $SalesReturnPreviewRoute on GoRouteData {
  static SalesReturnPreviewRoute _fromState(GoRouterState state) =>
      SalesReturnPreviewRoute(
        orderId: state.pathParameters['orderId']!,
        returnExchangeId: state.pathParameters['returnExchangeId']!,
      );

  SalesReturnPreviewRoute get _self => this as SalesReturnPreviewRoute;

  @override
  String get location => GoRouteData.$location(
    '/sales/orders/${Uri.encodeComponent(_self.orderId)}/returns/${Uri.encodeComponent(_self.returnExchangeId)}/preview',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
