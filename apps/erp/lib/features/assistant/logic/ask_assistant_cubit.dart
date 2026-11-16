import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/assistant/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'ask_assistant_state.dart';

class AskAssistantCubit extends Cubit<AskAssistantState> {
  AskAssistantCubit({
    required AssistantRepository repository,
    required String Function() tenantId,
  }) : _repository = repository,
       _tenantId = tenantId,
       super(const AskAssistantState());

  static const maxQuestionLength = 500;
  static const maxHistoryTurns = 6;

  final AssistantRepository _repository;
  final String Function() _tenantId;
  String? _lastQuestion;

  Future<void> send(String question) async {
    final text = question.trim();
    if (text.isEmpty || text.length > maxQuestionLength) return;
    if (state.waiting || state.locked) return;
    final history = _history();
    emit(state.copyWith(messages: [...state.messages, UserMessage(text)], waiting: true));
    await _ask(text, history);
  }

  Future<void> retry() async {
    final text = _lastQuestion;
    if (text == null || state.waiting || state.locked) return;
    final messages = [...state.messages];
    if (messages.isNotEmpty && messages.last is ErrorMessage) messages.removeLast();
    final history = _history(messages.isNotEmpty ? messages.sublist(0, messages.length - 1) : messages);
    emit(state.copyWith(messages: messages, waiting: true));
    await _ask(text, history);
  }

  Future<void> _ask(String text, List<AssistantTurn> history) async {
    _lastQuestion = text;
    try {
      final reply = await _repository.ask(
        tenantId: _tenantId(),
        question: text,
        history: history,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          messages: [...state.messages, AssistantMessage(reply)],
          waiting: false,
          locked: state.locked || reply.status == AssistantStatus.hetLuot,
          remaining: reply.remaining ?? state.remaining,
        ),
      );
    } catch (error, stackTrace) {
      if (isClosed) return;
      final exception = AppException.from(error, stackTrace);
      emit(
        state.copyWith(
          messages: [
            ...state.messages,
            ErrorMessage(offline: exception.code == AppErrorCode.network),
          ],
          waiting: false,
        ),
      );
    }
  }

  /// Chữ thuần của các lượt trước câu đang hỏi (bỏ lỗi), cắt [maxHistoryTurns] cuối.
  List<AssistantTurn> _history([List<ChatMessage>? source]) {
    final turns = <AssistantTurn?>[
      for (final m in source ?? state.messages)
        switch (m) {
          UserMessage(:final text) => AssistantTurn(role: 'user', text: text),
          AssistantMessage(:final reply) => AssistantTurn(role: 'assistant', text: reply.text),
          ErrorMessage() => null,
        },
    ].whereType<AssistantTurn>().toList();
    return turns.length <= maxHistoryTurns ? turns : turns.sublist(turns.length - maxHistoryTurns);
  }
}
