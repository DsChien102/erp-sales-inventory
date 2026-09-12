import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:erp/features/sales/presentation/lookups/sales_partner_customer_lookup.dart';

void main() {
  test('search sends active customer-only Partner query', () async {
    final getIt = GetIt.asNewInstance();
    final module = _RecordingPartnerModule();
    getIt.registerSingleton<IPartnerModule>(module);
    getIt.registerSingleton<IExecutionContext>(const _TestExecutionContext());

    final items = await SalesPartnerCustomerLookup.bindSearch(getIt)('  An  ');

    final query = module.queries.single as SearchPartnersQuery;
    expect(query.tenantId, 'tenant-1');
    expect(query.query, 'An');
    expect(query.role, PartnerRoleType.customer);
    expect(query.status, PartnerStatus.active);
    expect(items.single.partnerId, 'partner-1');
  });

  test('duplicate check normalizes inputs and resolves first detail', () async {
    final getIt = GetIt.asNewInstance();
    final module = _RecordingPartnerModule(
      duplicateMatches: const [
        PartnerDuplicateMatchDto(
          partnerId: 'partner-dup',
          displayName: 'Dup',
          matchedField: PartnerDuplicateMatchField.phone,
          matchLevel: PartnerDuplicateMatchLevel.exact,
          partnerType: PartnerType.person,
        ),
      ],
    );
    getIt.registerSingleton<IPartnerModule>(module);
    getIt.registerSingleton<IExecutionContext>(const _TestExecutionContext());

    final duplicate = await SalesPartnerCustomerLookup.bindDuplicateCheck(getIt)(
      const SalesQuickCustomerDraft(
        type: SalesQuickCustomerType.person,
        displayName: '  Nguyen Van B  ',
        phone: '0988 123 456',
        taxCode: ' 031 234 ',
      ),
    );

    final query = module.queries.first as CheckDuplicatePartnersQuery;
    final detail = module.queries.last as GetPartnerDetailQuery;
    expect(query.tenantId, 'tenant-1');
    expect(query.phone, '0988123456');
    expect(query.taxCode, '031234');
    expect(query.name, 'Nguyen Van B');
    expect(detail.partnerId, 'partner-dup');
    expect(duplicate?.partnerId, 'partner-1');
    expect(duplicate?.phone, '0988123456');
  });

  test('person creation sends customer role and returns backend detail', () async {
    final getIt = GetIt.asNewInstance();
    final module = _RecordingPartnerModule();
    getIt.registerSingleton<IPartnerModule>(module);
    getIt.registerSingleton<IExecutionContext>(const _TestExecutionContext());

    final selection = await SalesPartnerCustomerLookup.bindCreate(getIt)(
      const SalesQuickCustomerDraft(
        type: SalesQuickCustomerType.person,
        displayName: ' Nguyen Van B ',
        phone: '0988 123 456',
        taxCode: ' 031 234 ',
        address: ' 12 Le Loi ',
      ),
      confirmDuplicate: true,
    );

    final command = module.commands.single as CreatePartnerCommand;
    expect(command.tenantId, 'tenant-1');
    expect(command.actorId, 'user-1');
    expect(command.partnerType, PartnerType.person);
    expect(command.roles, [PartnerRoleType.customer]);
    expect(command.confirmDuplicate, isTrue);
    expect(command.personProfile?.fullName, 'Nguyen Van B');
    expect(command.personProfile?.phone, '0988123456');
    expect(command.personProfile?.taxCode, '031234');
    expect(command.personProfile?.delivery?.address, '12 Le Loi');
    expect(selection.partnerId, 'partner-created');
  });

  test('organization creation sends organization profile', () async {
    final getIt = GetIt.asNewInstance();
    final module = _RecordingPartnerModule();
    getIt.registerSingleton<IPartnerModule>(module);
    getIt.registerSingleton<IExecutionContext>(const _TestExecutionContext());

    await SalesPartnerCustomerLookup.bindCreate(getIt)(
      const SalesQuickCustomerDraft(
        type: SalesQuickCustomerType.organization,
        displayName: ' Cong ty B ',
        phone: '028 3822 1122',
        address: ' 1 Pasteur ',
      ),
      confirmDuplicate: false,
    );

    final command = module.commands.single as CreatePartnerCommand;
    expect(command.partnerType, PartnerType.organization);
    expect(command.organizationProfile?.organizationType, OrganizationType.other);
    expect(command.organizationProfile?.organizationName, 'Cong ty B');
    expect(command.organizationProfile?.phone, '02838221122');
    expect(command.organizationProfile?.companyAddress, '1 Pasteur');
    expect(command.confirmDuplicate, isFalse);
  });

  test('no permission maps to neutral sales exception', () async {
    final getIt = GetIt.asNewInstance();
    final module = _RecordingPartnerModule(
      createError: const PartnerBlockedException(PartnerBlockedCodes.noPermission),
    );
    getIt.registerSingleton<IPartnerModule>(module);
    getIt.registerSingleton<IExecutionContext>(const _TestExecutionContext());

    await expectLater(
      SalesPartnerCustomerLookup.bindCreate(getIt)(
        const SalesQuickCustomerDraft(
          type: SalesQuickCustomerType.person,
          displayName: 'Nguyen Van B',
          phone: '0988123456',
        ),
        confirmDuplicate: false,
      ),
      throwsA(
        isA<SalesCustomerOperationException>().having(
          (error) => error.message,
          'message',
          'Bạn chưa có quyền tạo khách hàng.',
        ),
      ),
    );
  });
}

final class _RecordingPartnerModule implements IPartnerModule {
  _RecordingPartnerModule({
    this.duplicateMatches = const [],
    this.createError,
  });

  final List<Object> commands = [];
  final List<Object> queries = [];
  final List<PartnerDuplicateMatchDto> duplicateMatches;
  final Object? createError;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    if (createError != null) throw createError!;
    return const CreatePartnerResult(partnerId: 'partner-created') as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    queries.add(query);
    if (query is SearchPartnersQuery) {
      return const PartnerSearchResultDto(
            items: [
              PartnerListItemDto(
                partnerId: 'partner-1',
                displayName: 'Backend Customer',
                partnerType: PartnerType.person,
                status: PartnerStatus.active,
                roles: [PartnerRoleType.customer],
                phone: '0988123456',
              ),
            ],
            page: 1,
            limit: 40,
            total: 1,
          )
          as TResult;
    }
    if (query is CheckDuplicatePartnersQuery) {
      return duplicateMatches as TResult;
    }
    if (query is GetPartnerDetailQuery) {
      final detailQuery = query as GetPartnerDetailQuery;
      return PartnerDetailDto(
            partnerId: detailQuery.partnerId == 'partner-created' ? 'partner-created' : 'partner-1',
            partnerType: PartnerType.person,
            status: PartnerStatus.active,
            displayName: detailQuery.partnerId == 'partner-created'
                ? 'Created Customer'
                : 'Backend Customer',
            roles: const [PartnerRoleType.customer],
            availableActions: const [],
            expectedVersion: 1,
            personProfile: const PersonProfileDto(
              fullName: 'Backend Customer',
              phone: '0988123456',
            ),
          )
          as TResult;
    }
    throw StateError('Unexpected query $query');
  }
}

final class _TestExecutionContext implements IExecutionContext {
  const _TestExecutionContext();

  @override
  String get correlationId => 'corr-1';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'user-1';
}
