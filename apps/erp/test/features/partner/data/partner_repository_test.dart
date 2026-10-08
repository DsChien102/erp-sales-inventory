import 'package:erp/features/partner/data/models/partner_action_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson maps snake_case logs and empty snapshots to null', () {
    final page = PartnerActionLogPage.fromJson({
      'items': [
        {
          'action_log_id': 'al-1',
          'action_type': 'add_contact',
          'actor_user_id': '8acac7ec-0000-4000-8000-000000000001',
          'reason': null,
          'before_state': <String, dynamic>{},
          'after_state': <String, dynamic>{},
          'created_at': '2026-07-16T18:26:00',
        },
      ],
      'total': 1,
      'page': 1,
      'limit': 20,
    });

    expect(page.items, hasLength(1));
    expect(page.items.single.actionType, PartnerActionType.addContact);
    expect(page.items.single.beforeState, isNull);
    expect(page.items.single.afterState, isNull);
    expect(page.total, 1);
    expect(page.page, 1);
    expect(page.limit, 20);
  });

  test('missing total, page, and limit fall back to the item list', () {
    final page = PartnerActionLogPage.fromJson({
      'items': [
        {
          'action_log_id': 'al-1',
          'action_type': 'create',
          'actor_user_id': 'user-1',
          'created_at': '2026-07-14T23:26:00',
        },
      ],
    });

    expect(page.total, 1);
    expect(page.page, 1);
    expect(page.limit, 1);
    expect(page.items.single.actionType, PartnerActionType.create);
  });
}
