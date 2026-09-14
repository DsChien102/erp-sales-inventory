import 'package:get_it/get_it.dart';
import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import '../support/fake_pricing_rpc_supabase.dart';

void main() {
  test(
    'startup registers sales pricing gateway, validators, and access metadata',
    () {
      final container = GetIt.asNewInstance();
      PricingStartup.initializeForTesting(
        container: container,
        supabase: FakePricingRpcSupabase(),
        executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
        permissionChecker: FakePermissionChecker(),
        tenantAccessChecker: FakeTenantAccessChecker(),
      );

      expect(container.isRegistered<ISalesPricingReadGateway>(), isTrue);
      expect(
        container.isRegistered<PreviewSalesWorkingStatePricingQueryValidator>(),
        isTrue,
      );
      expect(
        container.isRegistered<EvaluateSalesManualPriceQueryValidator>(),
        isTrue,
      );
      final metadata = container.get<IAccessMetadataRegistry>();
      expect(
        metadata.forType(PreviewSalesWorkingStatePricingQuery)?.permission,
        PricingPermissions.previewSalesPricing,
      );
      expect(
        metadata.forType(EvaluateSalesManualPriceQuery)?.permission,
        PricingPermissions.adjustSalesPrice,
      );
    },
  );
}
