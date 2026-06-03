class OutboxMessage {
  final String id;
  final DateTime occurredOn;
  final String type;
  final String data;
  DateTime? processedDate;

  OutboxMessage({
    required this.id,
    required this.occurredOn,
    required this.type,
    required this.data,
  });
}
