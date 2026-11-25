import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../core/di/injection.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/session/session_repository.dart';
import '../../../core/session/session_state.dart';
import '../../tenant_context/presentation/tenant_context_selector.dart';
import '../data/default_pair_repository.dart';
import '../logic/default_pair_gate_cubit.dart';
import 'widgets/default_pair_gate_error_view.dart';
import 'widgets/erp_side_navigation.dart';

const _unboundedWidth = VResponsiveValue<double>(
  mobile: double.infinity,
  tablet: double.infinity,
  desktop: double.infinity,
);

/// Route Theme 1 tự bó cột thân trong trang (10-8): ở ≥ 1024 không bó 1120.
const _unboundedPrefixes = <String>[
  '/more/organization-profile',
  '/more/users',
  '/more/roles',
  '/more/audit-logs',
  '/more/my-account',
];

/// `true` khi [path] là Trang chủ (`/`) hoặc nằm dưới một route Theme 1 tự bó
/// cột. So khớp theo đoạn: `/more/users` không dính `/more/users-and-roles`.
@visibleForTesting
bool shellRouteIsUnbounded(String path) {
  if (path == '/') return true;
  for (final p in _unboundedPrefixes) {
    if (path == p || path.startsWith('$p/')) return true;
  }
  return false;
}

/// Outer shell for the store area.
///
/// Responsibilities:
/// - Bootstraps the user session once via [_SessionBootstrap].
/// - Validates the store-warehouse default pair gate via [DefaultPairGateCubit].
///   Loading and gate errors are displayed full-screen without navigation rails.
/// - On wide/desktop viewports (≥ 1024), renders [ErpSideNavigation] (icon rail,
///   84px) on the left and limits the content width to [VContentWidth] (1120px),
///   except on Trang chủ (`/`) and the Theme 1 routes in [shellRouteIsUnbounded],
///   which span the full width and bound themselves. The path is read from
///   `GoRouterState.uri.path`: after a `push`, `matchedLocation` stays on the
///   root page and only `uri` is the pushed one (go_router 17.5).
/// - On narrow/mobile viewports (< 1024), renders the child as-is (the tab scaffold
///   renders the bottom navigation bar on root tab screens).
class StoreShell extends StatelessWidget {
  const StoreShell({
    super.key,
    required this.child,
    this.repository,
    this.defaultPairRepository,
    this.autoBootstrap = true,
    this.initialState,
  });

  final Widget child;
  final SessionRepository? repository;
  final DefaultPairRepository? defaultPairRepository;
  final bool autoBootstrap;
  final SessionState? initialState;

  @override
  Widget build(BuildContext context) {
    final shellBody = _StoreShellBody(
      defaultPairRepository: defaultPairRepository,
      child: child,
    );

    if (repository != null || initialState != null) {
      return BlocProvider(
        create: (_) {
          final cubit = SessionController(
            repository: repository ?? getIt<SessionRepository>(),
            initialState: initialState,
          );
          if (autoBootstrap) {
            cubit.bootstrap();
          }
          return cubit;
        },
        child: shellBody,
      );
    }

    return BlocProvider.value(
      value: getIt<SessionController>(),
      child: _SessionBootstrap(
        enabled: autoBootstrap,
        child: shellBody,
      ),
    );
  }
}

class _SessionBootstrap extends StatefulWidget {
  const _SessionBootstrap({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_SessionBootstrap> createState() => _SessionBootstrapState();
}

class _SessionBootstrapState extends State<_SessionBootstrap> {
  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SessionController>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _StoreShellBody extends StatelessWidget {
  const _StoreShellBody({
    required this.child,
    required this.defaultPairRepository,
  });

  final Widget child;
  final DefaultPairRepository? defaultPairRepository;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionController, SessionState>(
      builder: (context, state) {
        // Phiên đang nạp dùng chung màn chờ toàn màn hình với cổng kho mặc định,
        // để sau đăng nhập chỉ thấy một màn chờ, không lồng loader trong khung tab.
        if (state.status == TenantLoadStatus.initial ||
            state.status == TenantLoadStatus.loading) {
          return _buildLoadingHold(context);
        }
        if (!state.isValid) {
          return _buildLayout(context, child);
        }
        return BlocProvider(
          key: ValueKey(state.current?.tenantId),
          create: (_) {
            final repository =
                defaultPairRepository ?? getIt<DefaultPairRepository>();
            return DefaultPairGateCubit(repository: repository)..load();
          },
          child: BlocBuilder<DefaultPairGateCubit, DefaultPairGateState>(
            builder: (context, gate) {
              if (gate.status != DefaultPairGateStatus.ready) {
                return _buildGateHold(context, gate);
              }
              return _buildLayout(context, child);
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingHold(BuildContext context) {
    return Scaffold(
      backgroundColor: context.vColors.background,
      body: const Center(child: VLoading()),
    );
  }

  Widget _buildGateHold(BuildContext context, DefaultPairGateState gate) {
    if (gate.status == DefaultPairGateStatus.loading) {
      return _buildLoadingHold(context);
    }
    return Scaffold(
      backgroundColor: context.vColors.background,
      body: SafeArea(
        child: DefaultPairGateErrorView(
          onRetry: () => context.read<DefaultPairGateCubit>().load(),
          onChooseOrganization: () => openTenantContextSelector(context),
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context, Widget content) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= VBreakpoints.desktop;
        if (!isDesktop) {
          return content;
        }
        // Trang chủ (10-8b) và route Theme 1 (10-8d) tự bó cột thân; route khác
        // giữ bó 1120 đến khi theme của nó được rà. Luôn bọc VContentWidth, chỉ
        // đổi bề ngang tối đa: đổi hình dạng cây sẽ dựng lại Navigator và mất state.
        final unbounded = shellRouteIsUnbounded(GoRouterState.of(context).uri.path);

        return Material(
          color: context.vColors.background,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ErpSideNavigation(),
              Expanded(
                child: VContentWidth(
                  maxWidth: unbounded ? _unboundedWidth : null,
                  child: content,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
