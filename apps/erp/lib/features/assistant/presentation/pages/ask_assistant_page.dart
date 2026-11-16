import 'package:erp/features/assistant/logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../widgets/assistant_composer.dart';
import '../widgets/assistant_footer.dart';
import '../widgets/assistant_message_bubble.dart';
import '../widgets/assistant_suggestions.dart';

/// Cần [AskAssistantCubit] cung cấp bởi `BlocProvider` phía trên.
class AskAssistantPage extends StatefulWidget {
  const AskAssistantPage({super.key});

  @override
  State<AskAssistantPage> createState() => _AskAssistantPageState();
}

class _AskAssistantPageState extends State<AskAssistantPage> {
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

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: const VAppBar(title: 'Hỏi VET45'),
      body: BlocConsumer<AskAssistantCubit, AskAssistantState>(
        listenWhen: (a, b) => a.messages.length != b.messages.length || a.waiting != b.waiting,
        listener: (_, _) => _scrollToEnd(),
        builder: (context, state) {
          final cubit = context.read<AskAssistantCubit>();
          return Column(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 840),
                    child: ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.all(VSpacing.md),
                      children: [
                        if (state.messages.isEmpty && !state.waiting)
                          AssistantSuggestions(onPick: cubit.send),
                        for (var i = 0; i < state.messages.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: VSpacing.cozy),
                            child: AssistantMessageBubble(
                              message: state.messages[i],
                              onRetry: i == state.messages.length - 1 ? cubit.retry : null,
                            ),
                          ),
                        if (state.waiting) const AssistantWaitingBubble(),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 840),
                    child: Column(
                      children: [
                        AssistantComposer(
                          controller: _controller,
                          waiting: state.waiting,
                          locked: state.locked,
                          onSend: _send,
                        ),
                        AssistantFooter(remaining: state.remaining),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
