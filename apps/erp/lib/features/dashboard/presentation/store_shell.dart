import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

/// Outer shell for the store area.
///
/// Responsibilities:
/// - Bootstraps the user session once via [_SessionBootstrap].
/// - Validates the store-warehouse default pair gate via [DefaultPairGateCubit].
///   Loading and gate errors are displayed full-screen without navigation rails.
/// - On wide/desktop viewports (≥ 1024), renders [ErpSideNavigation] on the left
///   and limits the content width to [VContentWidth] (1120px).
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

  Widget _buildGateHold(BuildContext context, DefaultPairGateState gate) {
    final dynamicColors = context.vColors;
    return Scaffold(
      backgroundColor: dynamicColors.background,
      body: gate.status == DefaultPairGateStatus.loading
          ? const Center(child: VLoading())
          : SafeArea(
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

        return Material(
          color: context.vColors.background,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ErpSideNavigation(),
              Expanded(
                child: VContentWidth(child: content),
              ),
            ],
          ),
        );
      },
    );
  }
}
