import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/src/bloc/partner_detail_cubit.dart';
import 'package:vet45_partner_presentation/src/bloc/partner_detail_state.dart';
import 'package:vet45_partner_presentation/src/bloc/partner_list_state.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakeExecutionContext implements IExecutionContext {
  @override
  String get correlationId => 'test-correlation';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'user-1';
}

final class _FakePartnerModule implements IPartnerModule {
  DeletePartnerCommand? lastDeleteCommand;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    if (command is! DeletePartnerCommand) {
      throw UnimplementedError('Unexpected command: $command');
    }

    final deleteCommand = command as DeletePartnerCommand;
    lastDeleteCommand = deleteCommand;
    return DeletePartnerResult(
      businessPartnerId: deleteCommand.partnerId,
    ) as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetPartnerDetailQuery) {
      return PartnerDetailDto(
        id: 'partner-1',
        displayName: 'Nguyen Van A',
        phone: '0912345678',
        roles: const {PartnerRole.customer},
        entityType: EntityType.individual,
        status: PartnerStatus.active,
        createdAt: DateTime.parse('2026-07-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-07-01T00:00:00Z'),
        version: 2,
        createdBy: 'user-1',
        updatedBy: 'user-1',
        hasBusinessData: false,
      ) as TResult;
    }
    throw UnimplementedError('Unexpected query: $query');
  }
}

PartnerItemModel _partnerItem() {
  return const PartnerItemModel(
    id: 'partner-1',
    avatarText: 'NA',
    name: 'Nguyen Van A',
    role: 'Khách hàng',
    status: 'Đang hoạt động',
    phone: '0912345678',
    email: '',
    taxId: '',
    updatedAt: '08:00 01/07/2026',
    version: 2,
    hasBusinessData: false,
  );
}

void main() {
  group('PartnerDetailCubit.deletePartner', () {
    test('scn_e02_u02_fr04_01 marks partner deleted on success', () async {
      final partnerModule = _FakePartnerModule();
      final cubit = PartnerDetailCubit(
        partnerModule: partnerModule,
        executionContext: _FakeExecutionContext(),
        initialPartner: _partnerItem(),
      );

      final result = await cubit.deletePartner();

      expect(result, isTrue);
      expect(cubit.state.wasDeleted, isTrue);
      expect(cubit.state.partner, isNull);
      expect(cubit.state.deleteMessage, 'Đã xóa hồ sơ đối tác.');
      expect(partnerModule.lastDeleteCommand?.partnerId, 'partner-1');
      expect(partnerModule.lastDeleteCommand?.hasBusinessData, isFalse);
    });

    test('does not delete when partner has business data', () async {
      final partnerModule = _FakePartnerModule();
      final cubit = PartnerDetailCubit(
        partnerModule: partnerModule,
        executionContext: _FakeExecutionContext(),
        initialPartner: _partnerItem(),
      );

      cubit.emit(
        cubit.state.copyWith(hasBusinessData: true),
      );

      final result = await cubit.deletePartner();

      expect(result, isFalse);
      expect(partnerModule.lastDeleteCommand, isNull);
      expect(cubit.state.wasDeleted, isFalse);
    });

    test('loads hasBusinessData from detail query', () async {
      final partnerModule = _FakePartnerModule();
      final cubit = PartnerDetailCubit(
        partnerModule: partnerModule,
        executionContext: _FakeExecutionContext(),
      );

      await cubit.load('partner-1');

      expect(cubit.state.status, PartnerDetailStatus.success);
      expect(cubit.state.hasBusinessData, isFalse);
      expect(cubit.state.canDelete, isTrue);
    });
  });
}
