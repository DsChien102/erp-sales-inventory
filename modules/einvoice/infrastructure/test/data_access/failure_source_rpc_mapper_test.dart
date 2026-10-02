import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/data_access/electronic_invoice_rpc_mapper.dart';

void main() {
  test('failure source maps to upper-case wire values', () {
    expect(
      ElectronicInvoiceRpcMapper.failureSourceToRpc(FailureSource.provider),
      'PROVIDER',
    );
    expect(
      ElectronicInvoiceRpcMapper.failureSourceToRpc(FailureSource.internal),
      'INTERNAL',
    );
    expect(ElectronicInvoiceRpcMapper.failureSourceToRpc(null), isNull);
  });
}
