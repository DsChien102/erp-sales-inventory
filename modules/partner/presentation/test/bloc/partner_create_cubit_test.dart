import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _RecordingPartnerModule implements IPartnerModule {
  final commands = <ICommand<Object?>>[];
  final queries = <IQuery<Object?>>[];
  PartnerDetailDto? detailOverride;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command as ICommand<Object?>);
    if (command is UpdatePartnerProfileCommand) {
      final update = command as UpdatePartnerProfileCommand;
      return UpdatePartnerProfileResult(
            partnerId: update.partnerId,
            expectedVersion: update.expectedVersion + 1,
          )
          as TResult;
    }
    return const CreatePartnerResult(partnerId: 'p-created') as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query as IQuery<Object?>);
    if (query is GetPartnerDetailQuery) {
      final detailQuery = query as GetPartnerDetailQuery;
      final detail =
          detailOverride ??
          PartnerDetailDto(
            partnerId: detailQuery.partnerId,
            partnerType: PartnerType.person,
            status: PartnerStatus.active,
            displayName: 'Nguyễn Văn A',
            roles: const [PartnerRoleType.customer],
            availableActions: const [PartnerAvailableAction.update],
            expectedVersion: 3,
            personProfile: const PersonProfileDto(
              fullName: 'Nguyễn Văn A',
              phone: '0901234567',
              email: 'a@example.com',
              taxCode: '0101234567',
            ),
          );
      return detail as TResult;
    }
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

  test('edit mode loadForEdit hydrates profile and hides primary contact', () async {
    final module = _RecordingPartnerModule();
    final cubit = PartnerCreateCubit.edit(
      partnerId: 'p-1',
      partnerModule: module,
      executionContext: executionContext,
    );

    expect(cubit.state.isEditMode, isTrue);
    expect(cubit.state.status, PartnerCreateStatus.loading);
    expect(cubit.state.sections, isNot(contains(PartnerCreateSection.primaryContact)));

    await cubit.loadForEdit();

    expect(cubit.state.status, PartnerCreateStatus.initial);
    expect(cubit.state.partnerId, 'p-1');
    expect(cubit.state.expectedVersion, 3);
    expect(cubit.state.fullName, 'Nguyễn Văn A');
    expect(cubit.state.phone, '0901234567');
    expect(cubit.state.email, 'a@example.com');
    expect(cubit.state.taxCode, '0101234567');
    expect(cubit.state.roles, [PartnerRoleType.customer]);
    expect(cubit.state.isDirty, isFalse);
    expect(cubit.state.canSubmit, isFalse);

    cubit.updateFullName('Nguyễn Văn B');
    expect(cubit.state.isDirty, isTrue);
    expect(cubit.state.canSubmit, isTrue);
  });

  test('edit submit maps to UpdatePartnerProfileCommand and excludes self on dup check', () async {
    final module = _RecordingPartnerModule();
    final cubit = PartnerCreateCubit.edit(
      partnerId: 'p-1',
      partnerModule: module,
      executionContext: executionContext,
    );
    await cubit.loadForEdit();

    cubit.updateFullName('Nguyễn Văn B');
    await cubit.submit();

    final dupQuery = module.queries.whereType<CheckDuplicatePartnersQuery>().single;
    expect(dupQuery.excludePartnerId, 'p-1');

    final command = module.commands.single as UpdatePartnerProfileCommand;
    expect(command.partnerId, 'p-1');
    expect(command.expectedVersion, 3);
    expect(command.personProfile?.fullName, 'Nguyễn Văn B');
    expect(command.personProfile?.phone, '0901234567');
    expect(cubit.state.status, PartnerCreateStatus.success);
    expect(cubit.state.expectedVersion, 4);
  });

  test('edit organization load hydrates org fields', () async {
    final module = _RecordingPartnerModule()
      ..detailOverride = PartnerDetailDto(
        partnerId: 'p-org',
        partnerType: PartnerType.organization,
        status: PartnerStatus.active,
        displayName: 'Công ty ABC',
        roles: const [PartnerRoleType.supplier],
        availableActions: const [PartnerAvailableAction.update],
        expectedVersion: 2,
        organizationProfile: const OrganizationProfileDto(
          organizationType: OrganizationType.company,
          organizationName: 'Công ty ABC',
          phone: '02812345678',
          email: 'contact@abc.vn',
        ),
      );
    final cubit = PartnerCreateCubit.edit(
      partnerId: 'p-org',
      partnerModule: module,
      executionContext: executionContext,
    );

    await cubit.loadForEdit();

    expect(cubit.state.partnerType, PartnerType.organization);
    expect(cubit.state.organizationName, 'Công ty ABC');
    expect(cubit.state.organizationTypeLabel, 'Công ty/TNHH');
    expect(cubit.state.phone, '02812345678');
    expect(cubit.state.sections, isNot(contains(PartnerCreateSection.primaryContact)));
  });
}
