import 'package:vet45_shared_application/application.dart';

import '../../ports/i_iam_access_gateway.dart';
import '../../ports/i_iam_session_port.dart';

/// Loads principal+active-store for [tenantId] and applies it to [sessionPort].
Future<void> bindSessionFromAccessContext({
  required IIamAccessGateway accessGateway,
  required IIamSessionPort sessionPort,
  required String tenantId,
}) async {
  final context = await accessGateway.getSessionContext(tenantId: tenantId);
  if (context == null) {
    throw ApplicationException('Active store context is required.');
  }

  final storeId = context.activeStoreId?.trim();
  if (storeId == null || storeId.isEmpty) {
    throw ApplicationException('Active store context is required.');
  }

  sessionPort.apply(context);
}
