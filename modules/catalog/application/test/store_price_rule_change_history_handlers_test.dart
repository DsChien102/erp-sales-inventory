import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _RecordingStorePriceRuleGateway implements IStorePriceRuleGateway {
  StorePriceRuleChangeHistoryResultDto historyResult =
      const StorePriceRuleChangeHistoryResultDto(items: [], totalCount: 0);
  String? lastHistoryTenantId;
  int? lastHistoryLimit;
  int? lastHistoryOffset;

  @override
  Future<AppliedStorePriceRuleDto> apply({
    required ApplyStorePriceRuleCommand command,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StorePriceRuleDto?> getRule({required String tenantId}) {
    throw UnimplementedError();
  }

  @override
  Future<StorePriceRuleChangeHistoryResultDto> listChangeHistory({
    required String tenantId,
    int limit = 50,
    int offset = 0,
  }) async {
    lastHistoryTenantId = tenantId;
    lastHistoryLimit = limit;
    lastHistoryOffset = offset;
    return historyResult;
  }

  @override
  Future<ProductUnitPriceSuggestionDto> suggest({
    required SuggestProductUnitPriceQuery query,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StorePriceRuleDto> upsertRule({
    required String tenantId,
    required String name,
    required double listMarkupRatio,
    required double floorMarkupRatio,
    StorePriceRuleStatus status = StorePriceRuleStatus.active,
  }) {
    throw UnimplementedError();
  }
}

StorePriceRuleChangeHistoryEntryDto _entry({
  required String id,
  required DateTime occurredAt,
  double? listBefore,
  required double listAfter,
  double? floorBefore,
  required double floorAfter,
  bool isCurrent = false,
}) {
  return StorePriceRuleChangeHistoryEntryDto(
    id: id,
    occurredAt: occurredAt,
    actorDisplayName: 'abc12345',
    summary: 'Cập nhật khung giá cửa hàng',
    listMarkupBefore: listBefore,
    listMarkupAfter: listAfter,
    floorMarkupBefore: floorBefore,
    floorMarkupAfter: floorAfter,
    isCurrent: isCurrent,
  );
}

void main() {
  group('EPIC-06 / US-02 store rule change history handlers', () {
    test('scn_e06_u02_hist_01 delegates pagination to gateway', () async {
      final gateway = _RecordingStorePriceRuleGateway()
        ..historyResult = StorePriceRuleChangeHistoryResultDto(
          items: [
            _entry(
              id: 'h-2',
              occurredAt: DateTime.utc(2026, 7, 9, 10),
              listBefore: 0.12,
              listAfter: 0.15,
              floorBefore: 0.10,
              floorAfter: 0.10,
              isCurrent: true,
            ),
            _entry(
              id: 'h-1',
              occurredAt: DateTime.utc(2026, 7, 8, 10),
              listBefore: null,
              listAfter: 0.12,
              floorBefore: null,
              floorAfter: 0.10,
            ),
          ],
          totalCount: 2,
        );
      final handler = GetStorePriceRuleChangeHistoryQueryHandler(
        storePriceRuleGateway: gateway,
      );

      final result = await handler.handle(
        GetStorePriceRuleChangeHistoryQuery(
          tenantId: 'tenant-1',
          limit: 10,
          offset: 0,
        ),
      );

      expect(gateway.lastHistoryTenantId, 'tenant-1');
      expect(gateway.lastHistoryLimit, 10);
      expect(gateway.lastHistoryOffset, 0);
      expect(result.items, hasLength(2));
      expect(result.items.first.isCurrent, isTrue);
      expect(result.totalCount, 2);
    });

    test('scn_e06_u02_hist_04 rejects invalid limit', () async {
      final handler = GetStorePriceRuleChangeHistoryQueryHandler(
        storePriceRuleGateway: _RecordingStorePriceRuleGateway(),
      );

      expect(
        () => handler.handle(
          GetStorePriceRuleChangeHistoryQuery(
            tenantId: 'tenant-1',
            limit: 0,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
