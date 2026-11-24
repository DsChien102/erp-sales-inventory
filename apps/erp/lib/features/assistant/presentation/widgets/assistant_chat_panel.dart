import 'dart:math' as math;

import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/assistant/logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'assistant_composer.dart';
import 'assistant_footer.dart';
import 'assistant_message_bubble.dart';
import 'assistant_suggestions.dart';

/// Khung chat "Hỏi Mosaic Retail" nổi trên Trang chủ (10-8b) — prototype `home/html/app/board.js` `chatPanel()`.
///
/// Đọc [AskAssistantCubit] từ context. [wide]: cửa sổ web (dải đầu xanh, cột 720, gợi ý 2 cột);
/// hẹp: toàn màn iPhone. ⤢ mở `/ask` với cùng cubit (`extra`) để giữ cuộc trò chuyện.
class AssistantChatPanel extends StatefulWidget {
  const AssistantChatPanel({super.key, required this.wide, required this.onClose});

  final bool wide;
  final VoidCallback onClose;

  @override
  State<AssistantChatPanel> createState() => _AssistantChatPanelState();
}

class _AssistantChatPanelState extends State<AssistantChatPanel> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    context.read<AskAssistantCubit>().send(text);
  }

  void _expand() {
    // Lấy trước khi đóng: iPhone đóng = pop route khung, context này bị gỡ.
    final router = GoRouter.of(context);
    final cubit = context.read<AskAssistantCubit>();
    widget.onClose();
    router.push('/ask', extra: cubit);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final wide = widget.wide;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): widget.onClose},
      child: FocusScope(
        autofocus: true,
        child: Semantics(
          scopesRoute: !wide,
          explicitChildNodes: true,
          label: 'Hỏi Mosaic Retail',
          child: Material(
            color: c.surface,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = wide ? math.max(VSpacing.space6, (constraints.maxWidth - 720) / 2) : 0.0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!wide) SizedBox(height: MediaQuery.paddingOf(context).top),
                    _Head(wide: wide, onExpand: _expand, onClose: widget.onClose),
                    Expanded(
                      child: ColoredBox(
                        color: wide ? c.background : c.surface,
                        child: BlocConsumer<AskAssistantCubit, AskAssistantState>(
                          listenWhen: (a, b) =>
                              a.messages.length != b.messages.length || a.waiting != b.waiting,
                          listener: (_, _) => _scrollToEnd(),
                          builder: (context, state) => _Body(
                            state: state,
                            wide: wide,
                            side: side,
                            scroll: _scroll,
                          ),
                        ),
                      ),
                    ),
                    BlocBuilder<AskAssistantCubit, AskAssistantState>(
                      builder: (context, state) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.surface,
                          border: Border(top: VBorders.side(c.borderDefault)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            // iPhone: khung là route riêng (không Scaffold) → tự nổi trên bàn phím / vạch home.
                            bottom: wide
                                ? 0
                                : math.max(
                                    MediaQuery.viewInsetsOf(context).bottom,
                                    MediaQuery.viewPaddingOf(context).bottom,
                                  ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AssistantComposer(
                                controller: _controller,
                                waiting: state.waiting,
                                locked: state.locked,
                                onSend: _send,
                                autofocus: true,
                                height: wide ? 52 : 44,
                                padding: wide
                                    ? EdgeInsets.fromLTRB(side, VSpacing.space4, side, VSpacing.space2)
                                    : const EdgeInsets.fromLTRB(
                                        VSpacing.space4,
                                        VSpacing.space3,
                                        VSpacing.space4,
                                        VSpacing.space2,
                                      ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: wide ? VSpacing.space2 : 0),
                                child: AssistantFooter(remaining: state.remaining),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.wide, required this.onExpand, required this.onClose});

  final bool wide;
  final VoidCallback onExpand;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final fg = wide ? c.textInverse : c.textPrimary;
    final toolFg = wide ? c.textInverse : c.textSecondary;
    return Container(
      constraints: BoxConstraints(minHeight: wide ? 64 : 60),
      padding: wide
          ? const EdgeInsets.only(left: VSpacing.space5, right: VSpacing.space3)
          : const EdgeInsets.only(left: VSpacing.space4, right: VSpacing.space2),
      decoration: BoxDecoration(
        color: wide ? c.primary : c.surface,
        border: wide ? null : Border(bottom: BorderSide(color: c.textPrimary, width: 2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: wide ? c.textInverse.withValues(alpha: .16) : c.textPrimary,
              borderRadius: BorderRadius.circular(VRadius.r8),
            ),
            alignment: Alignment.center,
            child: VIcon(icon: VIcons.messageCircle, size: 16, color: c.textInverse),
          ),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                'Hỏi Mosaic Retail',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VTypography.bodyDefault.copyWith(
                  fontSize: wide ? 20 : 16,
                  height: wide ? 28 / 20 : 24 / 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.2,
                  color: fg,
                ),
              ),
            ),
          ),
          _Tool(icon: VIcons.maximize, label: 'Mở toàn màn hình', color: toolFg, wide: wide, onTap: onExpand),
          _Tool(icon: VIcons.close, label: 'Đóng', color: toolFg, wide: wide, onTap: onClose),
        ],
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({
    required this.icon,
    required this.label,
    required this.color,
    required this.wide,
    required this.onTap,
  });

  final VIcons icon;
  final String label;
  final Color color;
  final bool wide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VRadius.r8),
          hoverColor: wide ? c.textInverse.withValues(alpha: .14) : c.surfaceHoverStrong,
          child: SizedBox.square(
            dimension: VSpacing.minTouchTarget,
            child: Center(child: VIcon(icon: icon, size: 20, color: color)),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.wide, required this.side, required this.scroll});

  final AskAssistantState state;
  final bool wide;
  final double side;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AskAssistantCubit>();
    final padding = wide
        ? EdgeInsets.symmetric(vertical: VSpacing.space8, horizontal: side)
        : const EdgeInsets.all(VSpacing.space4);
    if (state.messages.isEmpty && !state.waiting) {
      // Chưa hỏi: lời chào + gợi ý dồn đáy.
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - padding.vertical),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Greeting(wide: wide, onPick: cubit.send),
              ],
            ),
          ),
        ),
      );
    }
    return ListView(
      controller: scroll,
      padding: padding,
      children: [
        for (var i = 0; i < state.messages.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: VSpacing.space3),
            child: AssistantMessageBubble(
              message: state.messages[i],
              onRetry: i == state.messages.length - 1 ? cubit.retry : null,
            ),
          ),
        if (state.waiting) const AssistantWaitingBubble(),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.wide, required this.onPick});

  final bool wide;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final chips = [
      for (final s in assistantSuggestions) _Chip(text: s, wide: wide, onTap: () => onPick(s)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          assistantGreeting,
          style: VTypography.bodyDefault.copyWith(
            fontSize: wide ? 16 : 14,
            height: wide ? 26 / 16 : 22 / 14,
            color: c.textSecondary,
          ),
        ),
        SizedBox(height: wide ? VSpacing.space4 : VSpacing.space3),
        if (wide)
          for (var r = 0; r < chips.length; r += 2) ...[
            if (r > 0) const SizedBox(height: VSpacing.space3),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: chips[r]),
                  const SizedBox(width: VSpacing.space3),
                  Expanded(child: r + 1 < chips.length ? chips[r + 1] : const SizedBox()),
                ],
              ),
            ),
          ]
        else
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(height: VSpacing.space2),
            Align(alignment: Alignment.centerLeft, child: chips[i]),
          ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.wide, required this.onTap});

  final String text;
  final bool wide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final radius = BorderRadius.circular(wide ? VRadius.card : VRadius.pill);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: VBorders.side(wide ? c.borderDefault : c.borderInput),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        hoverColor: c.surfaceBrand,
        child: Container(
          constraints: BoxConstraints(minHeight: wide ? 52 : VSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4, vertical: VSpacing.space2),
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: VTypography.bodyDefault.copyWith(color: c.textPrimary),
          ),
        ),
      ),
    );
  }
}
