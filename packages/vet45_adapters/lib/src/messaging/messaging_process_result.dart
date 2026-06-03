/// Result of a single messaging pipeline pass (outbox → inbox → internal commands).
final class MessagingProcessResult {
  const MessagingProcessResult({
    this.hadOutboxWork = false,
    this.hadInboxWork = false,
    this.hadInternalWork = false,
  });

  static const empty = MessagingProcessResult();

  final bool hadOutboxWork;
  final bool hadInboxWork;
  final bool hadInternalWork;

  bool get hadAnyWork => hadOutboxWork || hadInboxWork || hadInternalWork;

  MessagingProcessResult merge(MessagingProcessResult other) {
    return MessagingProcessResult(
      hadOutboxWork: hadOutboxWork || other.hadOutboxWork,
      hadInboxWork: hadInboxWork || other.hadInboxWork,
      hadInternalWork: hadInternalWork || other.hadInternalWork,
    );
  }
}
