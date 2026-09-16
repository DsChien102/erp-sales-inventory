import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';

void main() {
  test('customer snapshot carries buyer invoice identity', () {
    const snapshot = CustomerSnapshotDto(
      customerId: 'p1',
      displayName: 'Công ty ABC',
      phoneNumber: '0900000000',
      taxCode: '0101234567',
      existingDebtMinor: 0,
      buyerType: 'organization',
      invoiceLegalName: 'CÔNG TY TNHH ABC',
      invoiceAddress: '12 Nguyễn Trãi, Hà Nội',
      invoiceEmail: 'ketoan@abc.vn',
    );

    expect(snapshot.buyerType, equals('organization'));
    expect(snapshot.invoiceLegalName, equals('CÔNG TY TNHH ABC'));
    expect(snapshot.invoiceAddress, equals('12 Nguyễn Trãi, Hà Nội'));
    expect(snapshot.invoiceEmail, equals('ketoan@abc.vn'));
  });

  test('walk-in customer needs no invoice identity', () {
    const snapshot = CustomerSnapshotDto(
      customerId: 'p2',
      displayName: 'Khách',
      existingDebtMinor: 0,
    );
    expect(snapshot.buyerType, isNull);
    expect(snapshot.invoiceLegalName, isNull);
  });
}
