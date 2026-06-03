import 'cqrs.dart';

final class AttachCustomerCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  AttachCustomerCommand({
    required this.tenantId,
    String? id,
  }) : super(id);

  static const String type = 'sales.test.attach_customer';

  @override
  String get commandType => type;

  @override
  final String tenantId;

  @override
  Map<String, dynamic> toJson() => {'tenant_id': tenantId};

  factory AttachCustomerCommand.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    return AttachCustomerCommand(
      id: id,
      tenantId: json['tenant_id'] as String,
    );
  }
}
