import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/session/session_controller.dart';
import '../../../core/session/session_state.dart';
import '../../tenant_context/presentation/tenant_context_selector.dart';
import '../data/home_repository.dart';
import '../logic/home_cubit.dart';
import '../logic/home_state.dart';
import 'widgets/home_board.dart';

/// Bọc thân trang bằng provider của khung chat (app_router truyền vào; `dashboard` không import `assistant`).
typedef HomeAskScopeBuilder = Widget Function(Widget child);

/// Dựng khung chat "Hỏi Mosaic Retail". [homeContext] nằm dưới provider của [HomeAskScopeBuilder].
typedef HomeAskPanelBuilder =
    Widget Function(BuildContext homeContext, {required bool wide, required VoidCallback onClose});

/// Trang chủ APP-01 "Bảng giá chợ" (10-8b).
class HomeTabPage extends StatefulWidget {
  const HomeTabPage({
    super.key,
    required this.repository,
    this.now = DateTime.now,
    this.askScope,
    this.askPanel,
  });

  final HomeRepository repository;
  final DateTime Function() now;
  final HomeAskScopeBuilder? askScope;
  final HomeAskPanelBuilder? askPanel;

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  late final HomeCubit _cubit = HomeCubit(repository: widget.repository)..load();
  GoRouter? _router;
  String? _lastPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (!identical(router, _router)) {
      _router?.routerDelegate.removeListener(_onRoute);
      _router = router;
      _lastPath = _currentPath();
      router?.routerDelegate.addListener(_onRoute);
    }
  }

  String? _currentPath() => _router?.routerDelegate.currentConfiguration.uri.path;

  /// Trang nằm trong `indexedStack` nên không dựng lại khi quay về tab: tải lại khi đường dẫn về `/`.
  void _onRoute() {
    final path = _currentPath();
    if (path == '/' && _lastPath != null && _lastPath != '/') _cubit.load();
    _lastPath = path;
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRoute);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final wide = MediaQuery.sizeOf(context).width >= VBreakpoints.desktop;
    return BlocProvider.value(
      value: _cubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<SessionController, SessionState>(
            listenWhen: (a, b) =>
                b.current?.tenantId != null && a.current?.tenantId != b.current?.tenantId,
            listener: (_, _) => _cubit.load(reset: true),
          ),
          BlocListener<HomeCubit, HomeState>(
            listenWhen: (_, b) => b.refreshError != null,
            listener: (context, state) => VToast.show(
              context,
              title: 'Chưa tải lại được',
              message: 'Chưa tải lại được số liệu. ${state.refreshError!.userMessage()}',
              type: VToastType.danger,
            ),
          ),
        ],
        child: Scaffold(
          backgroundColor: colors.surface,
          body: BlocBuilder<SessionController, SessionState>(
            buildWhen: (a, b) =>
                a.branchDisplayName != b.branchDisplayName || a.isBlocked != b.isBlocked,
            builder: (context, session) {
              final branchName =
                  session.branchDisplayName ?? (session.isBlocked ? 'Chọn tổ chức' : 'Đang tải…');
              return BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) => HomeBoard(
                  state: state,
                  branchName: branchName,
                  onBranchTap: () => openTenantContextSelector(context),
                  now: widget.now(),
                  wide: wide,
                  onRetry: _cubit.load,
                  onRefresh: _cubit.load,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
