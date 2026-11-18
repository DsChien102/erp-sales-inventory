import 'dart:async';

import 'package:erp/features/assistant/data.dart';
import 'package:erp/features/assistant/logic.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'assistant_result_table.dart';

/// Chữ khi lỗi / mất mạng (AI-0 mục 8). Câu từ chối / lỗi khác lấy từ backend.
const assistantErrorText = 'Có lỗi khi trả lời. Bạn thử lại nhé.';
const assistantOfflineText = 'Không có kết nối mạng.';
const assistantWaitingText = 'Đang trả lời…';
const assistantWaitingSlowText = 'Vẫn đang xử lý, chờ chút nhé…';

/// Sau bao lâu thì đổi chữ chờ sang [assistantWaitingSlowText].
const assistantWaitingSlowAfter = Duration(seconds: 8);

class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({super.key, required this.message, this.onRetry});

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    switch (message) {
      case UserMessage(:final text):
        return Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.cozy,
                vertical: VSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(VRadius.r12),
              ),
              child: VText(text, color: c.textInverse),
            ),
          ),
        );
      case ErrorMessage(:final offline):
        return Align(
          alignment: Alignment.centerLeft,
          child: _Bubble(
            background: c.dangerBg,
            border: c.danger,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(offline ? assistantOfflineText : assistantErrorText),
                if (onRetry != null) ...[
                  const SizedBox(height: VSpacing.sm),
                  VButton(
                    label: 'Thử lại',
                    variant: VButtonVariant.secondary,
                    onPressed: onRetry,
                  ),
                ],
              ],
            ),
          ),
        );
      case AssistantMessage(:final reply):
        final blocks = [for (final b in reply.blocks) if (_drawable(b)) b];
        final isProblem = reply.status != AssistantStatus.ok &&
            reply.status != AssistantStatus.troChuyen;
        final tone = switch (reply.status) {
          AssistantStatus.loi => (c.dangerBg, c.danger),
          AssistantStatus.ok || AssistantStatus.troChuyen => (c.surface, c.borderDefault),
          _ => (c.warningBg, c.warning),
        };
        final bubble = _Bubble(
          background: tone.$1,
          border: isProblem ? tone.$2 : c.borderDefault,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reply.text.isNotEmpty) VText(reply.text),
              for (final block in blocks) ...[
                const SizedBox(height: VSpacing.cozy),
                AssistantResultTable(block: block),
              ],
            ],
          ),
        );
        return blocks.isEmpty
            ? Align(alignment: Alignment.centerLeft, child: bubble)
            : bubble;
    }
  }

  static bool _drawable(TableBlock b) => b.columns.isNotEmpty && b.rows.isNotEmpty;
}

class AssistantWaitingBubble extends StatefulWidget {
  const AssistantWaitingBubble({super.key});

  @override
  State<AssistantWaitingBubble> createState() => _AssistantWaitingBubbleState();
}

class _AssistantWaitingBubbleState extends State<AssistantWaitingBubble> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(assistantWaitingSlowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    return Align(
      alignment: Alignment.centerLeft,
      child: _Bubble(
        background: c.surface,
        border: c.borderDefault,
        child: VText(
          _slow ? assistantWaitingSlowText : assistantWaitingText,
          color: c.textSecondary,
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.background, required this.border, required this.child});

  final Color background;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(VSpacing.cozy),
    decoration: BoxDecoration(
      color: background,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(VRadius.r12),
    ),
    child: child,
  );
}
