import 'package:uuid/uuid.dart';

class InboxMessage {
  final String id;
  final DateTime occurredOn;
  final String type;
  final String data;
  DateTime? processedDate;

  InboxMessage({
    required this.occurredOn,
    required this.type,
    required this.data,
  }) : id = Uuid().v7();
}
