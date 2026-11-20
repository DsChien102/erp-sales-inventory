import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:erp/features/sales/presentation/lookups/sales_partner_customer_lookup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../partner/support/scripted_partner_repository.dart';

const _backendCustomer = PartnerDetailDto(
  partnerId: 'partner-1',
  partnerType: PartnerType.person,
  status: PartnerStatus.active,
  displayName: 'Backend Customer',
  roles: [PartnerRoleType.customer],
  availableActions: [],
  expectedVersion: 1,
  personProfile: PersonProfileDto(fullName: 'Backend Customer', phone: '0988123456'),
);

/// Repository kịch bản cho lookup bán hàng; [createError] / [detailError] ném khi gọi method đó.
ScriptedPartnerRepository _repo({
  List<PartnerDuplicateMatchDto> duplicateMatches = const [],
  Object? createError,
  PartnerDetailDto? detailOverride,
  Object? detailError,
}) {
  return ScriptedPartnerRepository(
    onCall: (method, args) {
      switch (method) {
        case 'search':
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
          );
        case 'checkDuplicates':
          return duplicateMatches;
        case 'create':
          if (createError != null) throw createError;
          return const CreatePartnerResult(partnerId: 'partner-created');
        case 'getDetail':
          if (detailError != null) throw detailError;
          if (detailOverride != null) return detailOverride;
          final partnerId = args['partnerId'] as String;
          return PartnerDetailDto(
            partnerId: partnerId == 'partner-created' ? 'partner-created' : 'partner-1',
            partnerType: PartnerType.person,
            status: PartnerStatus.active,
            displayName: partnerId == 'partner-created' ? 'Created Customer' : 'Backend Customer',
            roles: const [PartnerRoleType.customer],
            availableActions: const [],
            expectedVersion: 1,
            personProfile: const PersonProfileDto(
              fullName: 'Backend Customer',
              phone: '0988123456',
            ),
          );
      }
      throw StateError('Unexpected partner call $method');
    },
  );
}

GetIt _di(ScriptedPartnerRepository repo) {
  final getIt = GetIt.asNewInstance();
  getIt.registerSingleton<PartnerRepository>(repo);
  return getIt;
}

void main() {
  test('search sends active customer-only Partner query', () async {
    final module = _repo();

    final items = await SalesPartnerCustomerLookup.bindSearch(_di(module))('  An  ');

    final args = module.invocations.single.args;
    expect(module.invocations.single.method, 'search');
    expect(args['query'], 'An');
    expect(args['role'], PartnerRoleType.customer);
    expect(args['status'], PartnerStatus.active);
    expect(items.single.partnerId, 'partner-1');
  });

  test('duplicate check normalizes inputs and resolves first detail', () async {
    final module = _repo(
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

    final duplicate = await SalesPartnerCustomerLookup.bindDuplicateCheck(_di(module))(
      const SalesQuickCustomerDraft(
        type: SalesQuickCustomerType.person,
        displayName: '  Nguyen Van B  ',
        phone: '0988 123 456',
        taxCode: ' 031 234 ',
      ),
    );

    final query = module.invocations.first.args;
    final detail = module.invocations.last;
    expect(module.invocations.first.method, 'checkDuplicates');
    expect(query['phone'], '0988123456');
    expect(query['taxCode'], '031234');
    expect(query['name'], 'Nguyen Van B');
    expect(detail.method, 'getDetail');
    expect(detail.args['partnerId'], 'partner-dup');
    expect(duplicate?.partnerId, 'partner-1');
    expect(duplicate?.phone, '0988123456');
  });

  test('person creation sends customer role and returns backend detail', () async {
    final module = _repo();

    final selection = await SalesPartnerCustomerLookup.bindCreate(_di(module))(
      const SalesQuickCustomerDraft(
        type: SalesQuickCustomerType.person,
        displayName: ' Nguyen Van B ',
        phone: '0988 123 456',
        taxCode: ' 031 234 ',
        address: ' 12 Le Loi ',
      ),
      confirmDuplicate: true,
    );

    final args = module.callsOf('create').single.args;
    final profile = args['personProfile'] as PersonProfileInput?;
    expect(args['partnerType'], PartnerType.person);
    expect(args['roles'], [PartnerRoleType.customer]);
    expect(args['confirmDuplicate'], isTrue);
    expect(profile?.fullName, 'Nguyen Van B');
    expect(profile?.phone, '0988123456');
    expect(profile?.taxCode, '031234');
    expect(profile?.delivery?.address, '12 Le Loi');
    expect(selection.partnerId, 'partner-created');
  });

  test('organization creation sends organization profile', () async {
    final module = _repo();

    await SalesPartnerCustomerLookup.bindCreate(_di(module))(
      const SalesQuickCustomerDraft(
        type: SalesQuickCustomerType.organization,
        displayName: ' Cong ty B ',
        phone: '028 3822 1122',
        address: ' 1 Pasteur ',
      ),
      confirmDuplicate: false,
    );

    final args = module.callsOf('create').single.args;
    final profile = args['organizationProfile'] as OrganizationProfileInput?;
    expect(args['partnerType'], PartnerType.organization);
    expect(profile?.organizationType, OrganizationType.other);
    expect(profile?.organizationName, 'Cong ty B');
    expect(profile?.phone, '02838221122');
    expect(profile?.companyAddress, '1 Pasteur');
    expect(args['confirmDuplicate'], isFalse);
  });

  Future<void> expectCreateError(Object createError, String message) async {
    await expectLater(
      SalesPartnerCustomerLookup.bindCreate(_di(_repo(createError: createError)))(
        const SalesQuickCustomerDraft(
          type: SalesQuickCustomerType.person,
          displayName: 'Nguyen Van B',
          phone: '0988123456',
        ),
        confirmDuplicate: false,
      ),
      throwsA(
        isA<SalesCustomerOperationException>().having((e) => e.message, 'message', message),
      ),
    );
  }

  test('no permission maps to neutral sales exception', () async {
    await expectCreateError(
      const AppException(AppErrorCode.noPermission),
      'Bạn chưa có quyền tạo khách hàng.',
    );
  });

  test('H18 duplicate warning on create maps to neutral sales message', () async {
    await expectCreateError(
      const AppException('DUPLICATE_WARNING'),
      'Khách hàng có thể đã tồn tại. Vui lòng kiểm tra lại.',
    );
  });

  test('H18 other errors on create map to the connection message', () async {
    for (final error in <Object>[
      const AppException(AppErrorCode.validation, serverMessage: 'Phone format is invalid'),
      const AppException(AppErrorCode.network),
      Exception('socket'),
    ]) {
      await expectCreateError(error, 'Không thể kết nối để tạo khách hàng. Vui lòng thử lại.');
    }
  });

  test('H18 search without keyword limits to last 30 days, limit 40', () async {
    final module = _repo();

    await SalesPartnerCustomerLookup.bindSearch(_di(module))('   ');

    final args = module.invocations.single.args;
    expect(args['query'], isNull);
    expect(args['updatedWithinDays'], 30);
    expect(args['limit'], 40);
    expect(args['page'], 1);
  });

  test('H18 search with keyword does not limit by updated time', () async {
    final module = _repo();

    await SalesPartnerCustomerLookup.bindSearch(_di(module))('An');

    expect(module.invocations.single.args['updatedWithinDays'], isNull);
  });

  group('H18 resolve', () {
    PartnerDetailDto detail({
      PartnerStatus status = PartnerStatus.active,
      List<PartnerRoleType> roles = const [PartnerRoleType.customer],
    }) => PartnerDetailDto(
      partnerId: _backendCustomer.partnerId,
      partnerType: PartnerType.person,
      status: status,
      displayName: _backendCustomer.displayName,
      roles: roles,
      availableActions: const [],
      expectedVersion: 1,
      personProfile: _backendCustomer.personProfile,
    );

    Future<void> expectResolveError(
      ScriptedPartnerRepository repo,
      String message, {
      String id = 'partner-1',
    }) async {
      await expectLater(
        SalesPartnerCustomerLookup.bindResolve(_di(repo))(id),
        throwsA(
          isA<SalesExternalOperationException>().having((e) => e.message, 'message', message),
        ),
      );
    }

    test('inactive customer', () async {
      await expectResolveError(
        _repo(detailOverride: detail(status: PartnerStatus.inactive)),
        'Khách hàng không còn hoạt động.',
      );
    });

    test('partner without customer role', () async {
      await expectResolveError(
        _repo(detailOverride: detail(roles: const [PartnerRoleType.supplier])),
        'Đối tác không có vai trò khách hàng.',
      );
    });

    test('any lookup error', () async {
      await expectResolveError(
        _repo(detailError: const AppException(AppErrorCode.notFound)),
        'Không thể xác minh khách hàng. Vui lòng thử lại.',
      );
    });

    test('blank id', () async {
      await expectResolveError(_repo(), 'Khách hàng không hợp lệ.', id: '  ');
    });
  });
}
