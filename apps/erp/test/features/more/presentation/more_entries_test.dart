import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/more/presentation/more_entries.dart';

void main() {
  group('selectedMoreEntry', () {
    test('matches table 3.3 rules from W-1 spec', () {
      // /inventory, /warehouse -> Kho
      expect(selectedMoreEntry('/inventory')?.id, 'inventory');
      expect(selectedMoreEntry('/inventory/adjustments')?.id, 'inventory');
      expect(selectedMoreEntry('/warehouse')?.id, 'inventory');
      expect(selectedMoreEntry('/warehouse/receipts/quick/header')?.id, 'inventory');

      // /pricing -> Giá riêng / Nhớ giá
      expect(selectedMoreEntry('/pricing')?.id, 'pricing');
      expect(selectedMoreEntry('/pricing/custom')?.id, 'pricing');

      // Users and roles
      expect(selectedMoreEntry('/more/users-and-roles')?.id, 'users_and_roles');
      expect(selectedMoreEntry('/more/organization-profile')?.id, 'users_and_roles');
      expect(selectedMoreEntry('/more/users')?.id, 'users_and_roles');
      expect(selectedMoreEntry('/more/users/invite')?.id, 'users_and_roles');
      expect(selectedMoreEntry('/more/roles')?.id, 'users_and_roles');
      expect(selectedMoreEntry('/more/audit-logs')?.id, 'users_and_roles');

      // My account
      expect(selectedMoreEntry('/more/my-account')?.id, 'my_account');
      expect(selectedMoreEntry('/more/my-account/edit')?.id, 'my_account');

      // Settings
      expect(selectedMoreEntry('/more/settings')?.id, 'settings');
      expect(selectedMoreEntry('/more/einvoice')?.id, 'settings');
      expect(selectedMoreEntry('/more/product-settings')?.id, 'settings');

      // Exact /more -> null
      expect(selectedMoreEntry('/more'), isNull);

      // Other routes -> null
      expect(selectedMoreEntry('/orders'), isNull);
      expect(selectedMoreEntry('/'), isNull);
      expect(selectedMoreEntry('/products/items'), isNull);
      expect(selectedMoreEntry('/partner'), isNull);
    });
  });
}
