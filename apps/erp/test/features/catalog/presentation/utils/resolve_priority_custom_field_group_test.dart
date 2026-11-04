import 'package:erp/features/catalog/presentation/utils/resolve_priority_custom_field_group.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/catalog/data/models.dart';

void main() {
  CustomFieldGroupCardDto group({
    required String id,
    required int sortOrder,
    required bool hasRequiredMissing,
  }) {
    return CustomFieldGroupCardDto(
      groupId: id,
      name: id,
      sortOrder: sortOrder,
      hasRequiredMissing: hasRequiredMissing,
    );
  }

  test('returns null when groups empty', () {
    expect(resolvePriorityCustomFieldGroupId(const []), isNull);
  });

  test('returns null when no group has required missing', () {
    expect(
      resolvePriorityCustomFieldGroupId([
        group(id: 'a', sortOrder: 1, hasRequiredMissing: false),
        group(id: 'b', sortOrder: 2, hasRequiredMissing: false),
      ]),
      isNull,
    );
  });

  test('picks first hasRequiredMissing by sortOrder, not list order', () {
    expect(
      resolvePriorityCustomFieldGroupId([
        group(id: 'later', sortOrder: 2, hasRequiredMissing: true),
        group(id: 'first', sortOrder: 1, hasRequiredMissing: true),
      ]),
      'first',
    );
  });

  test('skips complete groups and picks next missing required', () {
    expect(
      resolvePriorityCustomFieldGroupId([
        group(id: 'done', sortOrder: 1, hasRequiredMissing: false),
        group(id: 'next', sortOrder: 2, hasRequiredMissing: true),
        group(id: 'also', sortOrder: 3, hasRequiredMissing: true),
      ]),
      'next',
    );
  });
}
