import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_infrastructure/src/errors/partner_error_mapper.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  group('mapPartnerRpcError', () {
    test('maps duplicate warning code from rpc message', () {
      final error = mapPartnerRpcError(
        RpcException('DUPLICATE_WARNING: phone already exists'),
      );

      expect(error.code, PartnerBlockedCodes.duplicateWarning);
    });

    test('maps permission denied message', () {
      final error = mapPartnerRpcError(
        RpcException('permission denied for function create_partner'),
      );

      expect(error.code, PartnerBlockedCodes.noPermission);
    });

    test('falls back to system error', () {
      final error = mapPartnerRpcError(RpcException('unexpected failure'));

      expect(error.code, PartnerBlockedCodes.systemError);
    });
  });
}
