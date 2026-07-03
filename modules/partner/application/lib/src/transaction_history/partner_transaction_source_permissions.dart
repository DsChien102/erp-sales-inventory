/// Maps projection source metadata to permission codes for deep-link checks.
abstract final class PartnerTransactionSourcePermissions {
  static String? forSource({
    required String sourceModule,
    required String sourceType,
  }) {
    return switch ((sourceModule, sourceType)) {
      ('sales', 'order') => 'sales.order.view',
      ('inventory', 'inbound') => 'inventory.inbound.view',
      ('accounting', 'receivable') => 'accounting.receivable.view',
      ('accounting', 'payable') => 'accounting.payable.view',
      _ => null,
    };
  }
}
