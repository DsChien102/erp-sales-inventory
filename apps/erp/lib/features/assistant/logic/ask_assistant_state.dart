import 'package:erp/features/assistant/data.dart';

sealed class ChatMessage {
  const ChatMessage();
}

class UserMessage extends ChatMessage {
  const UserMessage(this.text);
  final String text;
}

class AssistantMessage extends ChatMessage {
  const AssistantMessage(this.reply);
  final AssistantReply reply;
}

/// Mất mạng / lỗi HTTP; có nút Thử lại.
class ErrorMessage extends ChatMessage {
  const ErrorMessage({required this.offline});
  final bool offline;
}

class AskAssistantState {
  const AskAssistantState({
    this.messages = const [],
    this.waiting = false,
    this.locked = false,
    this.remaining,
  });

  final List<ChatMessage> messages;
  final bool waiting;
  final bool locked;
  final int? remaining;

  AskAssistantState copyWith({
    List<ChatMessage>? messages,
    bool? waiting,
    bool? locked,
    int? remaining,
  }) => AskAssistantState(
    messages: messages ?? this.messages,
    waiting: waiting ?? this.waiting,
    locked: locked ?? this.locked,
    remaining: remaining ?? this.remaining,
  );
}
