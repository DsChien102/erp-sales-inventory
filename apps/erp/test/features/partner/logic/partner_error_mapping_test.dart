// 4-A (H7–H13, H17): cách các cubit partner bắt lỗi. Câu lỗi theo TH-03 mục 6.4;
// các ca "Q2" từng hiện chuỗi kỹ thuật thô ở code cũ, nay trả câu "Không thể … Vui lòng thử lại.".
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/partner/data/models/partner_detail.dart';
import 'package:erp/features/partner/data/models/partner_duplicate_match.dart';
import 'package:erp/features/partner/data/models/partner_enums.dart';
import 'package:erp/features/partner/data/models/partner_inputs.dart';
import 'package:erp/features/partner/presentation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scripted_partner_repository.dart';

PartnerDetailDto _detail({
  List<PartnerRoleType> roles = const [PartnerRoleType.customer],
  PartnerType type = PartnerType.organization,
  String id = 'p-org',
}) => PartnerDetailDto(
  partnerId: id,
  partnerType: type,
  status: PartnerStatus.active,
  displayName: 'Cty ABC',
  roles: roles,
  availableActions: const [PartnerAvailableAction.update],
  expectedVersion: 2,
);

AppException _blocked(String code, {String? message}) => AppException(code, serverMessage: message);

void main() {
  group('H7 PartnerListCubit: lỗi giữ bộ lọc', () {
    test('lỗi tải → PartnerListError giữ query/type/role/status/time/sort', () async {
      final cubit = PartnerListCubit(
        repository: ScriptedPartnerRepository(onCall: (_, _) => throw _blocked('NO_PERMISSION')),
      );

      cubit.applyFilters(
        partnerType: PartnerType.organization,
        roleFilter: PartnerRoleFilter.supplier,
        status: PartnerStatus.inactive,
        updatedTimeFilter: PartnerUpdatedTimeFilter.values.first,
        sortOption: PartnerSortOption.nameAsc,
      );
      await pumpEventQueue();

      final state = cubit.state;
      expect(state, isA<PartnerListError>());
      expect(state.partnerType, PartnerType.organization);
      expect(state.roleFilter, PartnerRoleFilter.supplier);
      expect(state.status, PartnerStatus.inactive);
      expect(state.updatedTimeFilter, PartnerUpdatedTimeFilter.values.first);
      expect(state.sortOption, PartnerSortOption.nameAsc);
      await cubit.close();
    });

    test('lỗi tải giữ từ khoá tìm kiếm', () async {
      final cubit = PartnerListCubit(
        repository: ScriptedPartnerRepository(onCall: (_, _) => throw Exception('boom')),
      );

      cubit.searchByKeyword('abc');
      await pumpEventQueue();

      expect(cubit.state, isA<PartnerListError>());
      expect(cubit.state.query, 'abc');
      await cubit.close();
    });
  });

  group('H8 PartnerDetailCubit', () {
    test('roles rỗng → lỗi contact-only (isNotFound + isContactOnly)', () async {
      final cubit = PartnerDetailCubit(
        repository: ScriptedPartnerRepository(
          onCall: (_, _) => _detail(roles: const [], type: PartnerType.person),
        ),
      );

      await cubit.loadDetail('p-1');

      final state = cubit.state as PartnerDetailError;
      expect(state.isContactOnly, isTrue);
      expect(state.isNotFound, isTrue);
      expect(state.isNoPermission, isFalse);
    });

    test('NOT_FOUND → isNotFound', () async {
      final cubit = PartnerDetailCubit(
        repository: ScriptedPartnerRepository(onCall: (_, _) => throw _blocked('NOT_FOUND')),
      );

      await cubit.loadDetail('p-1');

      final state = cubit.state as PartnerDetailError;
      expect(state.isNotFound, isTrue);
      expect(state.isNoPermission, isFalse);
      expect(state.isContactOnly, isFalse);
    });

    test('NO_PERMISSION → isNoPermission', () async {
      final cubit = PartnerDetailCubit(
        repository: ScriptedPartnerRepository(onCall: (_, _) => throw _blocked('NO_PERMISSION')),
      );

      await cubit.loadDetail('p-1');

      final state = cubit.state as PartnerDetailError;
      expect(state.isNoPermission, isTrue);
      expect(state.isNotFound, isFalse);
    });

    test('lỗi khác → lỗi chung, không cờ nào bật', () async {
      final cubit = PartnerDetailCubit(
        repository: ScriptedPartnerRepository(
          onCall: (_, _) => throw const AppException(AppErrorCode.network),
        ),
      );

      await cubit.loadDetail('p-1');

      final state = cubit.state as PartnerDetailError;
      expect(state.isNotFound, isFalse);
      expect(state.isNoPermission, isFalse);
      expect(state.isContactOnly, isFalse);
    });

    test('tải được → PartnerDetailLoaded', () async {
      final repo = ScriptedPartnerRepository(onCall: (_, _) => _detail());
      final cubit = PartnerDetailCubit(repository: repo);

      await cubit.loadDetail('p-org');

      expect((cubit.state as PartnerDetailLoaded).detail.partnerId, 'p-org');
      expect(repo.invocations.single.args['partnerId'], 'p-org');
    });
  });

  group('H9 PartnerCreateCubit._mapFailure', () {
    Future<PartnerCreateCubit> submitWith(
      Object Function() error, {
      bool edit = false,
    }) async {
      final repo = ScriptedPartnerRepository(
        onCall: (method, _) {
          if (method == 'getDetail') return _detail(type: PartnerType.person, id: 'p-1');
          if (method == 'checkDuplicates') return <PartnerDuplicateMatchDto>[];
          throw error();
        },
      );
      final cubit = edit
          ? PartnerCreateCubit.edit(partnerId: 'p-1', repository: repo)
          : PartnerCreateCubit(partnerType: PartnerType.person, repository: repo);
      if (edit) await cubit.loadForEdit();
      cubit
        ..updateRoles(const [PartnerRoleType.customer])
        ..updateFullName('Nguyễn Văn Minh')
        ..updatePhone('0901234567');
      await cubit.submit();
      return cubit;
    }

    test('NO_PERMISSION khi tạo → blocked + câu tạo', () async {
      final cubit = await submitWith(() => _blocked('NO_PERMISSION'));
      expect(cubit.state.status, PartnerCreateStatus.blocked);
      expect(cubit.state.generalError, 'Bạn chưa có quyền tạo KH & NCC.');
    });

    test('NO_PERMISSION khi sửa → blocked + câu sửa', () async {
      final cubit = await submitWith(() => _blocked('NO_PERMISSION'), edit: true);
      expect(cubit.state.status, PartnerCreateStatus.blocked);
      expect(cubit.state.generalError, 'Bạn chưa có quyền chỉnh sửa KH & NCC.');
    });

    test('DUPLICATE_WARNING → failure + câu trùng', () async {
      final cubit = await submitWith(() => _blocked('DUPLICATE_WARNING'));
      expect(cubit.state.status, PartnerCreateStatus.failure);
      expect(
        cubit.state.generalError,
        'Đã tồn tại hồ sơ trùng MST/SĐT/email. Vui lòng kiểm tra lại.',
      );
    });

    test('STATE_CHANGED → failure + câu tải lại', () async {
      final cubit = await submitWith(() => _blocked('STATE_CHANGED'));
      expect(cubit.state.status, PartnerCreateStatus.failure);
      expect(
        cubit.state.generalError,
        'Hồ sơ đã được cập nhật bởi người khác. Vui lòng tải lại rồi thử lại.',
      );
    });

    test('NOT_FOUND → failure + câu không thấy hồ sơ', () async {
      final cubit = await submitWith(() => _blocked('NOT_FOUND'));
      expect(cubit.state.status, PartnerCreateStatus.failure);
      expect(
        cubit.state.generalError,
        'Không tìm thấy hồ sơ hoặc bạn không có quyền xem.',
      );
    });

    test(
      'Q2 — INVALID_STATUS → câu trạng thái không cho phép (trước: "Không thể lưu KH & NCC.")',
      () async {
        final cubit = await submitWith(() => _blocked('INVALID_STATUS'));
        expect(cubit.state.status, PartnerCreateStatus.failure);
        expect(
          cubit.state.generalError,
          'Trạng thái hồ sơ không cho phép thao tác này.',
        );
      },
    );

    test('Q2 — VALIDATION_ERROR, mạng, mã lạ → câu fallback, không hiện message thô', () async {
      for (final error in <Object Function()>[
        () => _blocked('VALIDATION_ERROR', message: 'Invalid partner payload'),
        () => const AppException(AppErrorCode.network),
        () => _blocked('X_UNKNOWN', message: 'chi tiết kỹ thuật'),
        () => Exception('socket'),
      ]) {
        final cubit = await submitWith(error);
        expect(cubit.state.status, PartnerCreateStatus.failure);
        expect(cubit.state.generalError, 'Không thể lưu dữ liệu. Vui lòng thử lại.');
      }
    });
  });

  group('H11 PartnerStatusCubit: mã lạ', () {
    PartnerStatusCubit cubitFailing(Object Function() error) => PartnerStatusCubit(
      repository: ScriptedPartnerRepository(onCall: (_, _) => throw error()),
    );

    test('INVALID_STATUS khi ngừng hoạt động → câu trạng thái không cho phép', () async {
      final cubit = cubitFailing(() => _blocked('INVALID_STATUS'));
      await cubit.deactivate(partnerId: 'p-1', expectedVersion: 1);
      expect(
        cubit.state.generalError,
        'Trạng thái hồ sơ không cho phép thao tác này.',
      );
    });

    test('INVALID_STATUS khi xoá → câu xoá riêng', () async {
      final cubit = cubitFailing(() => _blocked('INVALID_STATUS'));
      await cubit.softDelete(partnerId: 'p-1', expectedVersion: 1);
      expect(
        cubit.state.generalError,
        'Trạng thái hồ sơ không cho phép xóa.',
      );
    });

    test('Q2 — mã lạ → câu "Không thể … Vui lòng thử lại." của từng thao tác', () async {
      var cubit = cubitFailing(() => _blocked('X_UNKNOWN', message: 'raw'));
      await cubit.deactivate(partnerId: 'p-1', expectedVersion: 1);
      expect(cubit.state.status, PartnerStatusSubmitStatus.failure);
      expect(cubit.state.generalError, 'Không thể ngừng hoạt động. Vui lòng thử lại.');

      cubit = cubitFailing(() => _blocked('X_UNKNOWN', message: 'raw'));
      await cubit.reactivate(partnerId: 'p-1', expectedVersion: 1);
      expect(cubit.state.generalError, 'Không thể kích hoạt lại. Vui lòng thử lại.');

      cubit = cubitFailing(() => _blocked('X_UNKNOWN', message: 'raw'));
      await cubit.softDelete(partnerId: 'p-1', expectedVersion: 1);
      expect(cubit.state.generalError, 'Không thể xóa hồ sơ. Vui lòng thử lại.');
    });

    test('lỗi không phải partner → cùng câu', () async {
      var cubit = cubitFailing(() => Exception('x'));
      await cubit.deactivate(partnerId: 'p-1', expectedVersion: 1);
      expect(cubit.state.generalError, 'Không thể ngừng hoạt động. Vui lòng thử lại.');

      cubit = cubitFailing(() => Exception('x'));
      await cubit.reactivate(partnerId: 'p-1', expectedVersion: 1);
      expect(cubit.state.generalError, 'Không thể kích hoạt lại. Vui lòng thử lại.');

      cubit = cubitFailing(() => Exception('x'));
      await cubit.softDelete(partnerId: 'p-1', expectedVersion: 1);
      expect(cubit.state.generalError, 'Không thể xóa hồ sơ. Vui lòng thử lại.');
    });
  });

  group('H12 PartnerContactFormCubit: câu lỗi theo TH-03 6.4 (Q2)', () {
    PartnerContactFormCubit cubitFailing(Object Function() error) => PartnerContactFormCubit(
      repository: ScriptedPartnerRepository(
        onCall: (method, _) {
          if (method == 'checkDuplicates') return <PartnerDuplicateMatchDto>[];
          throw error();
        },
      ),
    );

    test('NO_PERMISSION khi tạo → câu thiếu quyền quản lý người liên hệ', () async {
      final cubit = cubitFailing(
        () => _blocked('NO_PERMISSION', message: 'Missing partner.contact.manage'),
      );
      await cubit.createContact(
        organizationPartnerId: 'org-1',
        fullName: 'Trần B',
        phone: '0901234567',
      );
      expect(cubit.state.status, PartnerContactFormStatus.error);
      expect(cubit.state.errorMessage, 'Bạn không có quyền quản lý người liên hệ.');
    });

    test('DUPLICATE_WARNING lọt qua (ignoreDuplicate) → câu trùng', () async {
      final cubit = cubitFailing(
        () => _blocked('DUPLICATE_WARNING', message: 'DUPLICATE_WARNING: [{"field":"phone"}]'),
      );
      await cubit.createContact(
        organizationPartnerId: 'org-1',
        fullName: 'Trần B',
        phone: '0901234567',
        ignoreDuplicate: true,
      );
      expect(cubit.state.status, PartnerContactFormStatus.error);
      expect(
        cubit.state.errorMessage,
        'Đã tồn tại hồ sơ trùng MST/SĐT/email. Vui lòng kiểm tra lại.',
      );
    });

    test('mã lạ khi sửa / liên kết → "Không thể lưu người liên hệ. Vui lòng thử lại."', () async {
      var cubit = cubitFailing(() => _blocked('X_UNKNOWN'));
      await cubit.editContact(
        organizationPartnerId: 'org-1',
        personPartnerId: 'per-1',
        fullName: 'Trần B',
        phone: '0901234567',
      );
      expect(cubit.state.errorMessage, 'Không thể lưu người liên hệ. Vui lòng thử lại.');

      cubit = cubitFailing(() => _blocked('X_UNKNOWN'));
      await cubit.linkExistingContact(
        organizationPartnerId: 'org-1',
        personPartnerId: 'per-1',
      );
      expect(cubit.state.errorMessage, 'Không thể lưu người liên hệ. Vui lòng thử lại.');
    });

    test('loadPersonDetail lỗi → câu không tải được thông tin', () async {
      final cubit = PartnerContactFormCubit(
        repository: ScriptedPartnerRepository(
          onCall: (_, _) => throw const AppException(AppErrorCode.network),
        ),
      );
      await cubit.loadPersonDetail('per-1');
      expect(cubit.state.status, PartnerContactFormStatus.error);
      expect(
        cubit.state.errorMessage,
        'Không tải được thông tin người liên hệ. Vui lòng thử lại.',
      );
    });

    test('loadPersonDetail NOT_FOUND → "Không tìm thấy hồ sơ."', () async {
      final cubit = PartnerContactFormCubit(
        repository: ScriptedPartnerRepository(onCall: (_, _) => throw _blocked('NOT_FOUND')),
      );
      await cubit.loadPersonDetail('per-1');
      expect(cubit.state.errorMessage, 'Không tìm thấy hồ sơ.');
    });
  });

  group('H13 PartnerContactsCubit: câu lỗi (Q2)', () {
    test('tải lỗi thiếu quyền → isNoPermission + câu thiếu quyền', () async {
      final cubit = PartnerContactsCubit(
        repository: ScriptedPartnerRepository(onCall: (_, _) => throw _blocked('NO_PERMISSION')),
      );
      await cubit.loadContacts('org-1');
      final state = cubit.state as PartnerContactsError;
      expect(state.isNoPermission, isTrue);
      expect(state.message, 'Bạn không có quyền thực hiện thao tác này.');
    });

    test('tải lỗi khác → không cờ thiếu quyền, câu fallback', () async {
      final cubit = PartnerContactsCubit(
        repository: ScriptedPartnerRepository(
          onCall: (_, _) => throw _blocked('X_UNKNOWN', message: 'raw'),
        ),
      );
      await cubit.loadContacts('org-1');
      final state = cubit.state as PartnerContactsError;
      expect(state.isNoPermission, isFalse);
      expect(state.message, 'Không tải được danh sách người liên hệ. Vui lòng thử lại.');
    });

    test('thao tác lỗi → actionError là câu fallback, isActionLoading=false', () async {
      final repo = ScriptedPartnerRepository(
        onCall: (method, _) {
          if (method == 'getDetail') return _detail(id: 'org-1');
          throw _blocked('X_UNKNOWN', message: 'raw');
        },
      );
      final cubit = PartnerContactsCubit(repository: repo);
      await cubit.loadContacts('org-1');
      const message = 'Không thể cập nhật người liên hệ. Vui lòng thử lại.';

      await cubit.setPrimaryContact('per-1');
      var loaded = cubit.state as PartnerContactsLoaded;
      expect(loaded.actionError, message);
      expect(loaded.isActionLoading, isFalse);

      await cubit.removeContact('per-1');
      loaded = cubit.state as PartnerContactsLoaded;
      expect(loaded.actionError, message);

      await cubit.addExistingContacts(const ['per-1']);
      loaded = cubit.state as PartnerContactsLoaded;
      expect(loaded.actionError, message);
      expect(loaded.isActionLoading, isFalse);
    });
  });

  group('H17 PartnerTransformCubit', () {
    const profile = OrganizationProfileInput(
      organizationType: OrganizationType.company,
      organizationName: 'Công ty A',
      phone: '02838225511',
    );

    PartnerTransformCubit cubitFailing(Object Function() error) => PartnerTransformCubit(
      repository: ScriptedPartnerRepository(onCall: (_, _) => throw error()),
    );

    test('DUPLICATE_WARNING có field tax_code → lỗi trường taxCode', () async {
      final cubit = cubitFailing(
        () => _blocked('DUPLICATE_WARNING', message: '[{"field":"tax_code"}]'),
      );
      await cubit.confirmTransform(
        partnerId: 'p-1',
        expectedVersion: 1,
        organizationProfile: profile,
      );
      expect(cubit.state.status, PartnerTransformSubmitStatus.duplicate);
      expect(cubit.state.fieldErrors.keys, ['taxCode']);
      expect(
        cubit.state.fieldErrors['taxCode'],
        PartnerTransformCubit.duplicateTaxCodeMessage,
      );
    });

    test('PRIMARY_CONTACT_OF_ORGANIZATION → câu riêng', () async {
      final cubit = cubitFailing(() => _blocked('PRIMARY_CONTACT_OF_ORGANIZATION'));
      await cubit.confirmTransform(
        partnerId: 'p-1',
        expectedVersion: 1,
        organizationProfile: profile,
      );
      expect(cubit.state.status, PartnerTransformSubmitStatus.failure);
      expect(
        cubit.state.generalError,
        'Hồ sơ này đang là người liên hệ chính của một tổ chức nên không thể chuyển đổi.',
      );
    });

    test('Q2 — mã lạ → câu chung (trước: message thô)', () async {
      final cubit = cubitFailing(() => _blocked('X_UNKNOWN', message: 'Lỗi gì đó'));
      await cubit.confirmTransform(
        partnerId: 'p-1',
        expectedVersion: 1,
        organizationProfile: profile,
      );
      expect(cubit.state.status, PartnerTransformSubmitStatus.failure);
      expect(
        cubit.state.generalError,
        'Không thể chuyển đổi hồ sơ. Vui lòng thử lại.',
      );
    });

    test('lỗi không phải partner → câu chung', () async {
      final cubit = cubitFailing(() => Exception('socket'));
      await cubit.confirmTransform(
        partnerId: 'p-1',
        expectedVersion: 1,
        organizationProfile: profile,
      );
      expect(cubit.state.status, PartnerTransformSubmitStatus.failure);
      expect(
        cubit.state.generalError,
        'Không thể chuyển đổi hồ sơ. Vui lòng thử lại.',
      );
    });
  });
}
