import 'package:erp/core/validation/tax_code.dart';
import 'package:erp/features/iam/logic/organization_profile_cubit.dart';
import 'package:erp/features/iam/logic/organization_profile_form_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';

import '../support/scripted_iam_repositories.dart';

void main() {
  OrganizationProfileCubit buildCubit(OrganizationScript mode) {
    return OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(mode: mode),
    );
  }

  const profileInput = TenantProfileFormInput(
    displayName: 'Mậu Hiên Updated',
    contactEmail: 'new@mauhien.vn',
    contactPhone: '+84901112233',
    contactAddressText: '456 Le Loi',
    provinceCode: '01',
    communeCode: '00001',
  );

  const legalInput = LegalProfileFormInput(
    legalEntityType: 'ENTERPRISE',
    legalName: 'New Legal Name',
    taxCode: '0123456789',
    registeredAddressText: '1 Nguyen Hue',
    provinceCode: '01',
    communeCode: '00001',
  );

  test('load fetches the current tenant', () async {
    final repository = ScriptedOrganizationRepository();
    final cubit = OrganizationProfileCubit(organizationRepository: repository);
    await cubit.load();
    expect(cubit.state.tenant, isNotNull);
    expect(cubit.state.tenant!.displayName, 'Mậu Hiên');
    expect(cubit.state.tenant!.tenantId, 'org-001');
    await cubit.close();
  });

  test('updateProfile uses current version', () async {
    final repository = ScriptedOrganizationRepository(mode: OrganizationScript.updateOk);
    final cubit = OrganizationProfileCubit(organizationRepository: repository);
    await cubit.load();
    final versionBefore = cubit.state.tenant!.version;
    final ok = await cubit.updateProfile(profileInput);
    expect(ok, isTrue);
    expect(repository.updates.single['expectedVersion'], versionBefore);
    expect(repository.updates.single['displayName'], 'Mậu Hiên Updated');
    expect(cubit.state.tenant!.version, greaterThan(versionBefore));
    await cubit.close();
  });

  test('tenantProfileValidation keeps form without success', () async {
    final cubit = buildCubit(OrganizationScript.validation);
    await cubit.load();
    final ok = await cubit.updateProfile(profileInput);
    expect(ok, isFalse);
    expect(cubit.state.failure?.code, IamBlockedCodes.validationError);
    expect(cubit.state.tenant, isNotNull);
    await cubit.close();
  });

  test('tenantProfileStale reloads and keeps failure', () async {
    final repository = ScriptedOrganizationRepository(mode: OrganizationScript.stale);
    final cubit = OrganizationProfileCubit(organizationRepository: repository);
    await cubit.load();
    final ok = await cubit.updateProfile(profileInput);
    expect(ok, isFalse);
    expect(cubit.state.failure?.code, IamBlockedCodes.stateChanged);
    expect(repository.updates, hasLength(1));
    await cubit.close();
  });

  test('tenantProfileForbidden maps permission denied', () async {
    final cubit = buildCubit(OrganizationScript.forbidden);
    await cubit.load();
    expect(cubit.state.failure?.code, IamBlockedCodes.permissionDenied);
    await cubit.close();
  });

  test('tenantProfileNotFound maps resource not found', () async {
    final cubit = OrganizationProfileCubit(
      organizationRepository: ScriptedOrganizationRepository(
        mode: OrganizationScript.notFound,
      ),
    );
    await cubit.load();
    expect(cubit.state.failure?.code, IamBlockedCodes.resourceNotFound);
    await cubit.close();
  });

  test('duplicate tax warning then confirm with allowDuplicateTaxCode', () async {
    final repository = ScriptedOrganizationRepository(
      mode: OrganizationScript.duplicateWarning,
    );
    final cubit = OrganizationProfileCubit(organizationRepository: repository);
    await cubit.load();

    final first = await cubit.upsertLegal(legalInput, allowDuplicateTaxCode: false);
    expect(first, isFalse);
    expect(cubit.state.duplicateWarning, isNotNull);
    expect(repository.upserts.first['allowDuplicateTaxCode'], isFalse);

    final confirmed = await cubit.confirmDuplicateLegal();
    expect(confirmed, isTrue);
    expect(repository.upserts.last['allowDuplicateTaxCode'], isTrue);
    expect(repository.upserts.last['taxCode'], repository.upserts.first['taxCode']);
    expect(cubit.state.duplicateWarning, isNull);
    expect(cubit.state.tenant!.legalProfile, isNotNull);
    await cubit.close();
  });

  test('client validation rejects empty displayName', () async {
    final repository = ScriptedOrganizationRepository(mode: OrganizationScript.updateOk);
    final cubit = OrganizationProfileCubit(organizationRepository: repository);
    await cubit.load();
    final ok = await cubit.updateProfile(const TenantProfileFormInput(displayName: '  '));
    expect(ok, isFalse);
    expect(repository.updates, isEmpty);
    expect(cubit.state.failure?.code, IamBlockedCodes.validationError);
    await cubit.close();
  });

  test('client validation rejects missing required contact fields', () async {
    final repository = ScriptedOrganizationRepository(mode: OrganizationScript.updateOk);
    final cubit = OrganizationProfileCubit(organizationRepository: repository);
    await cubit.load();
    final ok = await cubit.updateProfile(
      const TenantProfileFormInput(
        displayName: 'My Store',
        contactEmail: '',
        contactPhone: '',
        contactAddressText: '',
      ),
    );
    expect(ok, isFalse);
    expect(repository.updates, isEmpty);
    expect(cubit.state.failure?.code, IamBlockedCodes.validationError);
    expect(cubit.state.failure?.message, contains('email liên hệ'));
    expect(cubit.state.failure?.message, contains('số điện thoại'));
    expect(cubit.state.failure?.message, contains('địa chỉ liên hệ'));
    await cubit.close();
  });

  test('upsertLegal keeps the branch dash in the tax code sent', () async {
    final repository = ScriptedOrganizationRepository(mode: OrganizationScript.legalOk);
    final cubit = OrganizationProfileCubit(organizationRepository: repository);
    await cubit.load();

    await cubit.upsertLegal(
      const LegalProfileFormInput(
        legalEntityType: 'ENTERPRISE',
        legalName: 'Chi nhanh',
        taxCode: '0101234567-001',
      ),
      allowDuplicateTaxCode: false,
    );

    expect(repository.upserts.single['taxCode'], '0101234567-001');
    await cubit.close();
  });

  test('upsertLegal rejects 13 continuous digits (branch needs the dash)', () async {
    final repository = ScriptedOrganizationRepository(mode: OrganizationScript.legalOk);
    final cubit = OrganizationProfileCubit(organizationRepository: repository);
    await cubit.load();

    final ok = await cubit.upsertLegal(
      const LegalProfileFormInput(
        legalEntityType: 'HOUSEHOLD_BUSINESS',
        legalName: 'Ho kinh doanh',
        taxCode: '0101234567001',
      ),
      allowDuplicateTaxCode: false,
    );

    expect(ok, isFalse);
    expect(repository.upserts, isEmpty);
    expect(cubit.state.failure?.code, IamBlockedCodes.validationError);
    expect(cubit.state.failure?.message, taxCodeFormatMessage);
    await cubit.close();
  });
}
