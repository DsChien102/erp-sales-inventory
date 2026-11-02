import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import '../support/fake_partner_repository.dart';
import 'package:erp/features/partner/presentation.dart';
import '../support/scripted_partner_repository.dart';

void main() {
  test('confirmTransform dispatches transformToOrganization', () async {
    final module = ScriptedPartnerRepository(
      onCall: (_, args) => args['partnerId'],
    );
    final cubit = PartnerTransformCubit(repository: module);

    await cubit.confirmTransform(
      partnerId: 'p-1',
      expectedVersion: 3,
      organizationProfile: const OrganizationProfileInput(
        organizationType: OrganizationType.company,
        organizationName: 'Công ty TNHH An Phát',
        phone: '02838225511',
      ),
    );

    final call = module.invocations.single;
    expect(call.method, 'transformToOrganization');
    expect(call.args['partnerId'], 'p-1');
    expect(call.args['expectedVersion'], 3);
    expect(
      (call.args['organizationProfile'] as OrganizationProfileInput).organizationName,
      'Công ty TNHH An Phát',
    );
    expect(cubit.state.status, PartnerTransformSubmitStatus.success);
    expect(cubit.state.transformedPartnerId, 'p-1');
  });

  test('maps NO_PERMISSION to blocked noPermission', () async {
    final cubit = PartnerTransformCubit(
      repository: FakePartnerRepository(
        scenario: FakePartnerScenario.transformPermissionDenied,
      ),
    );

    await cubit.confirmTransform(
      partnerId: 'p-1',
      expectedVersion: 1,
      organizationProfile: const OrganizationProfileInput(
        organizationType: OrganizationType.company,
        organizationName: 'Công ty A',
        phone: '02838225511',
      ),
    );

    expect(cubit.state.status, PartnerTransformSubmitStatus.blocked);
    expect(cubit.state.blocked, PartnerTransformBlockedKind.noPermission);
  });

  test('maps STATE_CHANGED to blocked staleData', () async {
    final cubit = PartnerTransformCubit(
      repository: FakePartnerRepository(
        scenario: FakePartnerScenario.transformStateChanged,
      ),
    );

    await cubit.confirmTransform(
      partnerId: 'p-1',
      expectedVersion: 1,
      organizationProfile: const OrganizationProfileInput(
        organizationType: OrganizationType.company,
        organizationName: 'Công ty A',
        phone: '02838225511',
      ),
    );

    expect(cubit.state.status, PartnerTransformSubmitStatus.blocked);
    expect(cubit.state.blocked, PartnerTransformBlockedKind.staleData);
  });

  test('maps DUPLICATE_WARNING to friendly duplicate status', () async {
    final cubit = PartnerTransformCubit(
      repository: FakePartnerRepository(
        scenario: FakePartnerScenario.transformDupWarning,
      ),
    );

    await cubit.confirmTransform(
      partnerId: 'p-1',
      expectedVersion: 1,
      organizationProfile: const OrganizationProfileInput(
        organizationType: OrganizationType.company,
        organizationName: 'Công ty A',
        phone: '0981287110',
      ),
    );

    expect(cubit.state.status, PartnerTransformSubmitStatus.duplicate);
    expect(
      cubit.state.generalError,
      PartnerTransformCubit.duplicateUserMessage,
    );
    expect(cubit.state.fieldErrors['phone'], PartnerTransformCubit.duplicatePhoneMessage);
    expect(cubit.state.generalError, isNot(contains('PostgrestException')));
  });

  test('parseDuplicateFieldErrors maps phone email tax_code', () {
    const raw =
        '[{"code":"DUPLICATE_WARNING","field":"email"},'
        '{"code":"DUPLICATE_WARNING","field":"tax_code"}]';
    final errors = PartnerTransformCubit.parseDuplicateFieldErrors(raw);
    expect(errors['email'], PartnerTransformCubit.duplicateEmailMessage);
    expect(errors['taxCode'], PartnerTransformCubit.duplicateTaxCodeMessage);
    expect(errors.containsKey('phone'), isFalse);
  });
}
