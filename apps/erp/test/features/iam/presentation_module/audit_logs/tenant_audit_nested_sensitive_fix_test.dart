import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/features/iam/data/models/tenant_audit_log.dart';

import 'package:erp/features/iam/presentation/audit_logs/mappers/tenant_audit_ui_mapper.dart';

void main() {
  test('mapper recursively sanitizes nested sensitive values on both visible sides', () {
    final before = _nestedState('before');
    final after = _nestedState('after');

    final ui = TenantAuditUiMapper.fromDetail(
      _detail(beforeState: before, afterState: after),
    );

    final change = ui.changes.singleWhere(
      (row) => row.fieldKey == 'metadata',
    );
    final renderedValues = [
      change.beforeValue,
      change.afterValue,
      ui.beforeState,
      ui.afterState,
    ].join('\n');
    for (final raw in [..._rawValues('before'), ..._rawValues('after')]) {
      expect(renderedValues, isNot(contains(raw)), reason: raw);
    }
    expect(renderedValues, contains('[Đã che theo chính sách]'));
    expect(renderedValues, contains('visible-before'));
    expect(renderedValues, contains('visible-after'));
  });

  test('mapper never traverses a redacted side', () {
    final ui = TenantAuditUiMapper.fromDetail(
      _detail(
        beforeRedacted: true,
        beforeState: _NoTraversalMap(),
        afterState: const {'display_name': 'Visible after'},
      ),
    );

    expect(ui.beforeState, '[Đã che theo chính sách]');
    expect(ui.changes.single.beforeValue, '[Đã che theo chính sách]');
    expect(ui.changes.single.afterValue, 'Visible after');
  });
}

Map<String, Object?> _nestedState(String side) {
  final values = _rawValues(side);
  const keys = [
    'credential',
    'token',
    'password',
    'secret',
    'hash',
    'otp',
    'pin',
    'auth',
    'cookie',
    'bearer',
    'api-key',
    'private-key',
    'nonce',
    'session',
    'ciphertext',
  ];
  return {
    'metadata': [
      {
        for (var index = 0; index < keys.length; index++) keys[index]: values[index],
        'safe_label': 'visible-$side',
      },
    ],
  };
}

List<String> _rawValues(String side) {
  return List<String>.generate(15, (index) => 'RAW-$side-$index');
}

TenantAuditLogDetailDto _detail({
  bool beforeRedacted = false,
  Map<String, Object?>? beforeState,
  Map<String, Object?>? afterState,
}) {
  return TenantAuditLogDetailDto(
    auditLogId: 'audit-sensitive',
    tenantId: 'tenant-1',
    eventCode: IamAuditEvents.tenantProfileUpdated,
    result: TenantAuditLogResult.success,
    occurredAt: DateTime.utc(2026, 8, 20),
    source: 'iam',
    trackingId: 'tracking-sensitive',
    actorUnavailable: false,
    beforeRedacted: beforeRedacted,
    afterRedacted: false,
    actor: const TenantAuditActorDto(),
    subject: const TenantAuditSubjectDto(),
    beforeState: beforeState,
    afterState: afterState,
  );
}

final class _NoTraversalMap extends MapBase<String, Object?> {
  Never _fail() => throw StateError('redacted side was traversed');

  @override
  Object? operator [](Object? key) => _fail();

  @override
  void operator []=(String key, Object? value) => _fail();

  @override
  void clear() => _fail();

  @override
  Iterable<String> get keys => _fail();

  @override
  Object? remove(Object? key) => _fail();
}
