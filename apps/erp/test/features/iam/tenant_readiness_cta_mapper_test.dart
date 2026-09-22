import 'package:erp/features/iam/presentation/readiness/tenant_readiness_cta_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';

void main() {
  test('pending and expired owner invitation codes map to Vietnamese copy', () {
    expect(
      TenantReadinessCtaMapper.labelFor(
        TenantReadinessIssueCodes.ownerAcceptancePending,
      ),
      'Đang chờ chủ sở hữu chấp nhận lời mời',
    );
    expect(
      TenantReadinessCtaMapper.labelFor(
        TenantReadinessIssueCodes.ownerInvitationExpired,
      ),
      'Lời mời hết hạn',
    );
    expect(
      TenantReadinessCtaMapper.routeFor(
        TenantReadinessIssueCodes.ownerAcceptancePending,
      ),
      isNull,
    );
    expect(
      TenantReadinessCtaMapper.routeFor(
        TenantReadinessIssueCodes.ownerInvitationExpired,
      ),
      isNull,
    );
  });
}
