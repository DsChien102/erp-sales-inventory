import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _RecordingPartnerModule implements IPartnerModule {
  final commands = <ICommand<Object?>>[];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command as ICommand<Object?>);
    return const CreatePartnerResult(partnerId: 'p-created') as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    return <PartnerDuplicateMatchDto>[] as TResult;
  }
}

void main() {
  late FakeExecutionContext executionContext;

  setUp(() {
    executionContext = FakeExecutionContext(
      tenantId: 'tenant-1',
      userId: 'user-1',
    );
  });

  test('empty person submit exposes required errors and opens role section', () async {
    final cubit = PartnerCreateCubit(
      partnerType: PartnerType.person,
      partnerModule: _RecordingPartnerModule(),
      executionContext: executionContext,
    );

    await cubit.submit();

    expect(cubit.state.status, PartnerCreateStatus.failure);
    expect(cubit.state.errors.keys, containsAll(['roles', 'fullName', 'phone']));
    expect(cubit.state.activeSection, PartnerCreateSection.role);
  });

  test('setActiveSection toggles collapse when tapping expanded section', () {
    final cubit = PartnerCreateCubit(
      partnerType: PartnerType.person,
      partnerModule: _RecordingPartnerModule(),
      executionContext: executionContext,
    );

    expect(cubit.state.activeSection, PartnerCreateSection.role);
    cubit.setActiveSection(PartnerCreateSection.role);
    expect(cubit.state.activeSection, isNull);
    cubit.setActiveSection(PartnerCreateSection.main);
    expect(cubit.state.activeSection, PartnerCreateSection.main);
  });

  test('skip advances without completing while continue completes valid section', () {
    final cubit = PartnerCreateCubit(
      partnerType: PartnerType.person,
      partnerModule: _RecordingPartnerModule(),
      executionContext: executionContext,
    );

    cubit.skipActiveSection();
    expect(cubit.state.activeSection, PartnerCreateSection.main);
    expect(cubit.state.completedSections, isEmpty);

    cubit.updateFullName('Nguyễn Văn Minh');
    cubit.updatePhone('0901234567');
    cubit.continueActiveSection();
    expect(cubit.state.completedSections, contains(PartnerCreateSection.main));
    expect(cubit.state.activeSection, PartnerCreateSection.invoice);
  });

  test('person submit maps normalized draft to CreatePartnerCommand', () async {
    final module = _RecordingPartnerModule();
    final cubit = PartnerCreateCubit(
      partnerType: PartnerType.person,
      partnerModule: module,
      executionContext: executionContext,
    );

    cubit
      ..updateRoles(const [PartnerRoleType.customer])
      ..updateFullName('  Nguyễn Văn Minh  ')
      ..updatePhone('+84 901 234 567')
      ..updateEmail('minh@example.com');

    await cubit.submit();

    final command = module.commands.single as CreatePartnerCommand;
    expect(command.tenantId, 'tenant-1');
    expect(command.actorId, 'user-1');
    expect(command.personProfile?.fullName, 'Nguyễn Văn Minh');
    expect(command.personProfile?.phone, '+84901234567');
    expect(command.organizationPrimaryContact, isNull);
    expect(cubit.state.createdPartnerId, 'p-created');
  });

  test('organization submit includes optional primary contact atomically', () async {
    final module = _RecordingPartnerModule();
    final cubit = PartnerCreateCubit(
      partnerType: PartnerType.organization,
      partnerModule: module,
      executionContext: executionContext,
    );

    cubit
      ..updateRoles(const [PartnerRoleType.supplier])
      ..updateOrganizationName('Công ty TNHH An Phát')
      ..updatePhone('028 1234 5678')
      ..setPrimaryContactEnabled(true)
      ..updatePrimaryContactName('Trần Thị Lan')
      ..updatePrimaryContactPhone('0903 456 789');

    await cubit.submit();

    final command = module.commands.single as CreatePartnerCommand;
    expect(command.organizationProfile?.organizationName, 'Công ty TNHH An Phát');
    expect(command.organizationPrimaryContact?.fullName, 'Trần Thị Lan');
    expect(command.organizationPrimaryContact?.phone, '0903456789');
  });

  test('invalid optional email and tax code are rejected locally', () async {
    final cubit = PartnerCreateCubit(
      partnerType: PartnerType.person,
      partnerModule: _RecordingPartnerModule(),
      executionContext: executionContext,
    );

    cubit
      ..updateRoles(const [PartnerRoleType.customer])
      ..updateFullName('Nguyễn Văn Minh')
      ..updatePhone('0901234567')
      ..updateEmail('invalid-email')
      ..updateTaxCode('123');

    await cubit.submit();

    expect(cubit.state.errors['email'], 'Email không hợp lệ');
    expect(cubit.state.errors['taxCode'], 'MST phải có 10 hoặc 13 chữ số');
  });

  test('possible duplicate waits for confirmation then creates', () async {
    final cubit = PartnerCreateCubit(
      partnerType: PartnerType.person,
      partnerModule: FakePartnerModule(
        scenario: FakePartnerScenario.createDupWarning,
      ),
      executionContext: executionContext,
    );
    cubit
      ..updateRoles(const [PartnerRoleType.customer])
      ..updateFullName('Nguyễn Văn Trùng')
      ..updatePhone('0901234567');

    await cubit.submit();
    expect(cubit.state.status, PartnerCreateStatus.duplicate);
    expect(cubit.state.duplicateLevel, PartnerDuplicateMatchLevel.possible);

    await cubit.confirmPossibleDuplicate();
    expect(cubit.state.status, PartnerCreateStatus.success);
    expect(cubit.state.createdPartnerId, 'p-new-dup');
  });

  test('exact duplicate cannot be confirmed', () async {
    final cubit = PartnerCreateCubit(
      partnerType: PartnerType.organization,
      partnerModule: FakePartnerModule(
        scenario: FakePartnerScenario.createExactDuplicate,
      ),
      executionContext: executionContext,
    );
    cubit
      ..updateRoles(const [PartnerRoleType.supplier])
      ..updateOrganizationName('Công ty Trùng')
      ..updatePhone('02812345678')
      ..updateTaxCode('0101234567');

    await cubit.submit();

    expect(cubit.state.status, PartnerCreateStatus.duplicate);
    expect(cubit.state.duplicateLevel, PartnerDuplicateMatchLevel.exact);
    expect(cubit.canConfirmDuplicate, isFalse);
  });

  test('permission denial creates blocked read-only state and keeps draft', () async {
    final cubit = PartnerCreateCubit(
      partnerType: PartnerType.person,
      partnerModule: FakePartnerModule(
        scenario: FakePartnerScenario.createPermissionDenied,
      ),
      executionContext: executionContext,
    );
    cubit
      ..updateRoles(const [PartnerRoleType.customer])
      ..updateFullName('Nguyễn Văn Minh')
      ..updatePhone('0901234567');

    await cubit.submit();

    expect(cubit.state.status, PartnerCreateStatus.blocked);
    expect(cubit.state.fullName, 'Nguyễn Văn Minh');
    expect(cubit.state.isReadOnly, isTrue);
  });
}
