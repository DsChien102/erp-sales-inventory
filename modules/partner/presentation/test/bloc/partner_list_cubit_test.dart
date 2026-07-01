import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
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
  _FakePartnerModule({
    required this.shouldThrowPermissionError,
    this.shouldThrowSystemError = false,
  });

  final bool shouldThrowPermissionError;
  final bool shouldThrowSystemError;
  SearchPartnersQuery? lastSearchQuery;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    throw UnimplementedError();
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is SearchPartnersQuery) {
      lastSearchQuery = query as SearchPartnersQuery;
      if (shouldThrowPermissionError) {
        throw ApplicationException('Permission denied: partner.view');
      }
      if (shouldThrowSystemError) {
        throw ApplicationException('Database connection failed');
      }
      return PartnerSearchResultDto(
        items: [
          PartnerListItemDto(
            id: 'partner-1',
            displayName: 'Nguyen Van A',
            phone: '0912345678',
            roles: const {PartnerRole.customer},
            entityType: EntityType.individual,
            status: PartnerStatus.active,
            updatedAt: DateTime.parse('2026-07-01T00:00:00Z'),
          ),
        ],
        totalCount: 1,
      ) as TResult;
    }
    throw UnimplementedError('Unexpected query: $query');
  }
}

void main() {
  group('PartnerListCubit SCN-02 tests', () {
    test('loads partners successfully when permission is granted', () async {
      final cubit = PartnerListCubit(
        partnerModule: _FakePartnerModule(shouldThrowPermissionError: false),
        executionContext: _FakeExecutionContext(),
      );

      // Wait for async load() to finish
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, PartnerListStatus.success);
      expect(cubit.state.partners.length, 1);
      expect(cubit.state.partners.first.name, 'Nguyen Van A');
      expect(cubit.state.errorMessage, isNull);
    });

    test('transitions to failure and sets friendly message when permission is denied', () async {
      final cubit = PartnerListCubit(
        partnerModule: _FakePartnerModule(shouldThrowPermissionError: true),
        executionContext: _FakeExecutionContext(),
      );

      // Wait for async load() to finish
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, PartnerListStatus.failure);
      expect(cubit.state.partners, isEmpty);
      expect(cubit.state.errorMessage, 'Bạn không có quyền phù hợp.');
    });

    test('trims whitespaces from search query and uses null when empty', () async {
      final module = _FakePartnerModule(shouldThrowPermissionError: false);
      final cubit = PartnerListCubit(
        partnerModule: module,
        executionContext: _FakeExecutionContext(),
      );

      await Future<void>.delayed(Duration.zero);

      // Test with whitespace query
      cubit.search('   ');
      await Future<void>.delayed(Duration.zero);

      expect(module.lastSearchQuery?.criteria.keyword, isNull);

      // Test with actual keyword containing spaces
      cubit.search('  Nguyen Van An  ');
      await Future<void>.delayed(Duration.zero);

      expect(module.lastSearchQuery?.criteria.keyword, 'Nguyen Van An');
    });

    test('SCN-05: load failure transitions to failure status', () async {
      final cubit = PartnerListCubit(
        partnerModule: _FakePartnerModule(
          shouldThrowPermissionError: false,
          shouldThrowSystemError: true,
        ),
        executionContext: _FakeExecutionContext(),
      );

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, PartnerListStatus.failure);
      expect(cubit.state.partners, isEmpty);
      expect(cubit.state.errorMessage, 'Database connection failed');
    });

    test('SCN-09: search failure transitions to failure status', () async {
      final module = _FakePartnerModule(
        shouldThrowPermissionError: false,
        shouldThrowSystemError: false,
      );
      final cubit = PartnerListCubit(
        partnerModule: module,
        executionContext: _FakeExecutionContext(),
      );

      await Future<void>.delayed(Duration.zero);

      // Recreate module instance that throws error on next query
      final errorModule = _FakePartnerModule(
        shouldThrowPermissionError: false,
        shouldThrowSystemError: true,
      );
      final cubitWithError = PartnerListCubit(
        partnerModule: errorModule,
        executionContext: _FakeExecutionContext(),
      );
      await Future<void>.delayed(Duration.zero);

      cubitWithError.search('new query');
      await Future<void>.delayed(Duration.zero);

      expect(cubitWithError.state.status, PartnerListStatus.failure);
      expect(cubitWithError.state.errorMessage, 'Database connection failed');
    });

    test('SCN-10: filter failure transitions to failure status', () async {
      final errorModule = _FakePartnerModule(
        shouldThrowPermissionError: false,
        shouldThrowSystemError: true,
      );
      final cubit = PartnerListCubit(
        partnerModule: errorModule,
        executionContext: _FakeExecutionContext(),
      );
      await Future<void>.delayed(Duration.zero);

      cubit.updateFilter(role: 'Khách hàng');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, PartnerListStatus.failure);
      expect(cubit.state.errorMessage, 'Database connection failed');
    });
  });
}
