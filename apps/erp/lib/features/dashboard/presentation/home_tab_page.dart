import 'dart:math' as math;

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
    _fabFocus.dispose();
    _router?.routerDelegate.removeListener(_onRoute);
    _cubit.close();
    super.dispose();
  }

  /// Khung chat web đang mở (iPhone mở bằng route riêng, không dùng cờ này).
  bool _askOpen = false;
  final _fabFocus = FocusNode(debugLabel: 'Hỏi Mosaic Retail');

  void _openAsk(BuildContext inner, bool wide) {
    final panel = widget.askPanel;
    if (panel == null) return;
    if (wide) {
      setState(() => _askOpen = true);
      return;
    }
    // iPhone: toàn màn trên navigator gốc → che thanh dưới; cubit lấy từ [inner] nên còn cuộc trò chuyện.
    final navigator = Navigator.of(inner, rootNavigator: true);
    final reduce = MediaQuery.disableAnimationsOf(inner);
    navigator.push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: reduce ? Duration.zero : const Duration(milliseconds: 260),
        reverseTransitionDuration: reduce ? Duration.zero : const Duration(milliseconds: 200),
        pageBuilder: (routeContext, _, _) =>
            panel(inner, wide: false, onClose: () => Navigator.of(routeContext).maybePop()),
        transitionsBuilder: (_, animation, _, child) {
          final t = CurvedAnimation(parent: animation, curve: const Cubic(.16, 1, .3, 1));
          return FadeTransition(
            opacity: t,
            child: AnimatedBuilder(
              animation: t,
              builder: (_, c) =>
                  Transform.translate(offset: Offset(0, 24 * (1 - t.value)), child: c),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _closeAsk() {
    if (!_askOpen) return;
    setState(() => _askOpen = false);
    _fabFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final wide = MediaQuery.sizeOf(context).width >= VBreakpoints.desktop;
    final webOpen = _askOpen && wide;
    Widget content(BuildContext inner) => LayoutBuilder(
      builder: (_, area) => Stack(
        children: [
          Positioned.fill(
            child: BlocBuilder<SessionController, SessionState>(
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
          if (webOpen && widget.askPanel != null)
            _AskWindow(
              areaWidth: area.maxWidth,
              child: widget.askPanel!(inner, wide: true, onClose: _closeAsk),
            ),
          if (widget.askPanel != null)
            Positioned(
              right: wide ? VSpacing.space8 : VSpacing.space4,
              bottom: wide ? VSpacing.space8 : VSpacing.space4,
              child: _AskFab(
                open: webOpen,
                focusNode: _fabFocus,
                onTap: () => webOpen ? _closeAsk() : _openAsk(inner, wide),
              ),
            ),
        ],
      ),
    );
    final scope = widget.askScope;
    final body = scope == null
        ? Builder(builder: content)
        : KeyedSubtree(
            // Đổi tổ chức → cuộc trò chuyện mới.
            key: ValueKey(
              context.select<SessionController, String?>((s) => s.state.current?.tenantId),
            ),
            child: scope(Builder(builder: content)),
          );
    return BlocProvider.value(
      value: _cubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<SessionController, SessionState>(
            listenWhen: (a, b) =>
                b.current?.tenantId != null && a.current?.tenantId != b.current?.tenantId,
            listener: (_, _) {
              _cubit.load(reset: true);
              if (_askOpen) setState(() => _askOpen = false);
            },
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
        child: Scaffold(backgroundColor: colors.surface, body: body),
      ),
    );
  }
}

/// Cửa sổ chat web: trên 64, phải 32, dưới 32 + 56 + 12, rộng `min(1120, w − 64)`; vào 0.22 s mờ + dịch 8 + co .96.
class _AskWindow extends StatelessWidget {
  const _AskWindow({required this.areaWidth, required this.child});

  final double areaWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(VRadius.r16);
    final window = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: VBorders.all(c.borderDefault),
        boxShadow: const [
          BoxShadow(color: Color(0x1A0E1116), blurRadius: 24, offset: Offset(0, 8)),
          BoxShadow(color: Color(0x330E1116), blurRadius: 80, offset: Offset(0, 32)),
        ],
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
    return Positioned(
      top: 64,
      right: VSpacing.space8,
      bottom: VSpacing.space8 + 56 + VSpacing.space3,
      width: math.min(1120, areaWidth - 64),
      child: reduce
          ? window
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 220),
              curve: const Cubic(.16, 1, .3, 1),
              child: window,
              builder: (_, t, w) => Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - t)),
                  child: Transform.scale(
                    scale: .96 + .04 * t,
                    alignment: Alignment.bottomRight,
                    child: w,
                  ),
                ),
              ),
            ),
    );
  }
}

class _AskFab extends StatefulWidget {
  const _AskFab({required this.open, required this.focusNode, required this.onTap});

  final bool open;
  final FocusNode focusNode;
  final VoidCallback onTap;

  @override
  State<_AskFab> createState() => _AskFabState();
}

class _AskFabState extends State<_AskFab> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final label = widget.open ? 'Đóng Hỏi Mosaic Retail' : 'Hỏi Mosaic Retail';
    return Semantics(
      button: true,
      expanded: widget.open,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: 'Hỏi Mosaic Retail',
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VRadius.r16),
            boxShadow: const [
              BoxShadow(color: Color(0x1F0E1116), blurRadius: 24, offset: Offset(0, 8)),
            ],
          ),
          child: Material(
            color: _hover ? VColors.neutral700 : c.textPrimary,
            borderRadius: BorderRadius.circular(VRadius.r16),
            child: InkWell(
              focusNode: widget.focusNode,
              borderRadius: BorderRadius.circular(VRadius.r16),
              onHover: (v) => setState(() => _hover = v),
              onTap: widget.onTap,
              child: SizedBox.square(
                dimension: 56,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
                    transitionBuilder: (child, a) => RotationTransition(
                      turns: Tween(begin: -.25, end: 0.0).animate(a),
                      child: ScaleTransition(
                        scale: Tween(begin: .6, end: 1.0).animate(a),
                        child: FadeTransition(opacity: a, child: child),
                      ),
                    ),
                    child: VIcon(
                      key: ValueKey(widget.open),
                      icon: widget.open ? VIcons.close : VIcons.messageCircle,
                      size: 24,
                      color: c.textInverse,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
