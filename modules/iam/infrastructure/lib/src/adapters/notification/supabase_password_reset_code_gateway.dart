import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Fetches plaintext password-reset delivery code via service_role RPC.
///
/// Calls `iam.peek_password_reset_delivery_code` (superseded draft 022) — returns null
/// if the operation is expired, completed, or not found. Caller must treat
/// null as a terminal failure (skip send, record outcome failed).
final class SupabasePasswordResetCodeGateway
    implements IPasswordResetCodeGateway {
  SupabasePasswordResetCodeGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<String?> peekDeliveryCode(String operationId) async {
    try {
      final result = await _rpcClient.callScalar<String?>(
        'peek_password_reset_delivery_code',
        params: <String, dynamic>{'p_operation_id': operationId},
      );
      return result;
    } on RpcException {
      return null;
    }
  }
}
