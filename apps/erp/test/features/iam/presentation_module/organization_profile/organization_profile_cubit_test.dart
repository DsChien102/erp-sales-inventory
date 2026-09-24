import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:erp/features/iam/testing.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  OrganizationProfileCubit buildCubit(IIamModule module) {
    return OrganizationProfileCubit(
      iamModule: module,
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
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

  test('load fetches GetTenantQuery', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.tenantProfileOk),
    );
    final cubit = buildCubit(module);
    await cubit.load();
    expect(cubit.state.tenant, isNotNull);
    expect(cubit.state.tenant!.displayName, 'Mậu Hiên');
    expect(module.queriesOf<GetTenantQuery>().single.tenantId, 'org-001');
    await cubit.close();
  });

  test('updateProfile uses current version', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.tenantProfileUpdateOk),
    );
    final cubit = buildCubit(module);
    await cubit.load();
    final versionBefore = cubit.state.tenant!.version;
    final ok = await cubit.updateProfile(profileInput);
    expect(ok, isTrue);
    final command = module.commandsOf<UpdateTenantProfileCommand>().single;
    expect(command.expectedVersion, versionBefore);
    expect(command.displayName, 'Mậu Hiên Updated');
    expect(cubit.state.tenant!.version, greaterThan(versionBefore));
    await cubit.close();
  });

  test('tenantProfileValidation keeps form without success', () async {
    final cubit = buildCubit(
      FakeIamModule(scenario: FakeIamScenario.tenantProfileValidation),
    );
    await cubit.load();
    final ok = await cubit.updateProfile(profileInput);
    expect(ok, isFalse);
    expect(cubit.state.failure?.code, IamBlockedCodes.validationError);
    expect(cubit.state.tenant, isNotNull);
    await cubit.close();
  });

  test('tenantProfileStale reloads and keeps failure', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.tenantProfileStale),
    );
    final cubit = buildCubit(module);
    await cubit.load();
    final ok = await cubit.updateProfile(profileInput);
    expect(ok, isFalse);
    expect(cubit.state.failure?.code, IamBlockedCodes.stateChanged);
    expect(module.queriesOf<GetTenantQuery>().length, greaterThan(1));
    await cubit.close();
  });

  test('tenantProfileForbidden maps permission denied', () async {
    final cubit = buildCubit(
      FakeIamModule(scenario: FakeIamScenario.tenantProfileForbidden),
    );
    await cubit.load();
    expect(cubit.state.failure?.code, IamBlockedCodes.permissionDenied);
    await cubit.close();
  });

  test('tenantProfileNotFound maps resource not found', () async {
    final cubit = OrganizationProfileCubit(
      iamModule: FakeIamModule(scenario: FakeIamScenario.tenantProfileNotFound),
      executionContext: FakeExecutionContext(tenantId: 'missing'),
    );
    await cubit.load();
    expect(cubit.state.failure?.code, IamBlockedCodes.resourceNotFound);
    await cubit.close();
  });

  test('duplicate tax warning then confirm with allowDuplicateTaxCode', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.legalDuplicateWarning),
    );
    final cubit = buildCubit(module);
    await cubit.load();

    final first = await cubit.upsertLegal(
      legalInput,
      allowDuplicateTaxCode: false,
    );
    expect(first, isFalse);
    expect(cubit.state.duplicateWarning, isNotNull);
    final firstCommand = module.commandsOf<UpsertLegalProfileCommand>().first;
    expect(firstCommand.allowDuplicateTaxCode, isFalse);

    final confirmed = await cubit.confirmDuplicateLegal();
    expect(confirmed, isTrue);
    final secondCommand = module.commandsOf<UpsertLegalProfileCommand>().last;
    expect(secondCommand.allowDuplicateTaxCode, isTrue);
    expect(secondCommand.taxCode, firstCommand.taxCode);
    expect(cubit.state.duplicateWarning, isNull);
    expect(cubit.state.tenant!.legalProfile, isNotNull);
    await cubit.close();
  });

  test('client validation rejects empty displayName', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.tenantProfileUpdateOk),
    );
    final cubit = buildCubit(module);
    await cubit.load();
    final ok = await cubit.updateProfile(
      const TenantProfileFormInput(displayName: '  '),
    );
    expect(ok, isFalse);
    expect(module.commandsOf<UpdateTenantProfileCommand>(), isEmpty);
    expect(cubit.state.failure?.code, IamBlockedCodes.validationError);
    await cubit.close();
  });

  test('client validation rejects missing required contact fields', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.tenantProfileUpdateOk),
    );
    final cubit = buildCubit(module);
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
    expect(module.commandsOf<UpdateTenantProfileCommand>(), isEmpty);
    expect(cubit.state.failure?.code, IamBlockedCodes.validationError);
    expect(cubit.state.failure?.message, contains('email liên hệ'));
    expect(cubit.state.failure?.message, contains('số điện thoại'));
    expect(cubit.state.failure?.message, contains('địa chỉ liên hệ'));
    await cubit.close();
  });

  test('upsertLegal keeps the branch dash in the tax code sent', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.legalUpsertOk),
    );
    final cubit = buildCubit(module);
    await cubit.load();

    await cubit.upsertLegal(
      const LegalProfileFormInput(
        legalEntityType: 'ENTERPRISE',
        legalName: 'Chi nhanh',
        taxCode: '0101234567-001',
      ),
      allowDuplicateTaxCode: false,
    );

    final command = module.commandsOf<UpsertLegalProfileCommand>().single;
    expect(command.taxCode, '0101234567-001');
    await cubit.close();
  });

  test('upsertLegal rejects 13 continuous digits (branch needs the dash)', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.legalUpsertOk),
    );
    final cubit = buildCubit(module);
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
    expect(module.commandsOf<UpsertLegalProfileCommand>(), isEmpty);
    expect(cubit.state.failure?.code, IamBlockedCodes.validationError);
    expect(
      cubit.state.failure?.message,
      'Mã số thuế phải gồm 10 hoặc 12 chữ số, hoặc dạng chi nhánh 10 số-3 số (VD: 0123456789-001).',
    );
    await cubit.close();
  });
}
