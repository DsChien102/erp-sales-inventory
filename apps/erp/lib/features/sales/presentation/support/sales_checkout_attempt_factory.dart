import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_sales_application/application.dart';

import '../models/sales_order/sales_checkout_attempt_envelope.dart';
import '../models/sales_order/sales_checkout_draft_args.dart';
import '../models/sales_order/sales_checkout_vm.dart';

final class SalesCheckoutAttemptFactory {
  SalesCheckoutAttemptFactory({String Function()? newAttemptId})
    : _newAttemptId = newAttemptId ?? const Uuid().v4;

  final String Function() _newAttemptId;

  SalesCheckoutAttemptEnvelope create({
    required SalesCheckoutDraftArgs args,
    required SalesCheckoutVm vm,
    required String tenantId,
    required String actorId,
    required String storeId,
    required String correlationId,
  }) {
    final attemptId = _newAttemptId();
    final normalizedNote = _trimToNull(vm.note ?? args.orderNote);
    final paymentDueDate = _dateOnlyPayload(vm.dueDate);
    final paymentIntents = <PaymentIntentInput>[
      if (vm.cashPaidMinor > 0)
        PaymentIntentInput(
          method: SalesPaymentMethod.cash,
          amount: MoneyDto(
            amountMinor: vm.cashPaidMinor,
            currencyCode: args.currencyCode.trim().toUpperCase(),
          ),
        ),
      if (vm.bankPaidMinor > 0)
        PaymentIntentInput(
          method: SalesPaymentMethod.manualBankTransfer,
          amount: MoneyDto(
            amountMinor: vm.bankPaidMinor,
            currencyCode: args.currencyCode.trim().toUpperCase(),
          ),
          reference: _trimToNull(vm.transactionCode),
        ),
    ];
    final payload = <String, Object?>{
      'actorId': actorId.trim(),
      'currencyCode': args.currencyCode.trim().toUpperCase(),
      'customerId': _trimToNull(args.customerId),
      'commercialSnapshot': _commercialSnapshot(args.commercialSnapshot),
      'expectedSourceVersion': args.expectedSourceVersion,
      'lines': [
        for (final line in args.lines)
          <String, Object?>{
            'note': _trimToNull(line.note),
            'productId': line.productId.trim(),
            'productUnitId': line.productUnitId.trim(),
            'quantityMicros': line.quantity.quantityMicros,
            'unitPriceAmountMinor': line.unitPrice?.amountMinor,
            'unitPriceCurrencyCode': line.unitPrice?.currencyCode.trim().toUpperCase(),
          },
      ],
      'orderNote': normalizedNote,
      'paymentDueDate': paymentDueDate,
      'paymentIntents': [
        for (final intent in paymentIntents)
          <String, Object?>{
            'amountMinor': intent.amount.amountMinor,
            'currencyCode': intent.amount.currencyCode.trim().toUpperCase(),
            'method': intent.method.name,
            'reference': _trimToNull(intent.reference),
          },
      ],
      'sourceDraftId': _trimToNull(args.sourceDraftId),
      'storeId': storeId.trim(),
      'tenantId': tenantId.trim(),
    };
    final canonicalJson = jsonEncode(_sort(payload));
    final payloadHash = sha256.convert(utf8.encode(canonicalJson)).toString();
    final command = FinalizeSalesOrderCommand(
      id: attemptId,
      tenantId: tenantId.trim(),
      actorId: actorId.trim(),
      storeId: storeId.trim(),
      sourceDraftId: _trimToNull(args.sourceDraftId),
      customerId: _trimToNull(args.customerId),
      currencyCode: args.currencyCode.trim().toUpperCase(),
      orderNote: normalizedNote,
      paymentDueDate: _dateOnly(vm.dueDate),
      lines: args.lines,
      paymentIntents: paymentIntents,
      commercialSnapshot: args.commercialSnapshot,
      idempotencyKey: 'checkout:$attemptId',
      payloadHash: payloadHash,
      correlationId: correlationId.trim(),
      expectedSourceVersion: args.expectedSourceVersion,
    );
    return SalesCheckoutAttemptEnvelope(
      command: command,
      canonicalPayloadJson: canonicalJson,
      payloadHash: payloadHash,
    );
  }

  static Object? _sort(Object? value) {
    if (value is Map<String, Object?>) {
      final keys = value.keys.toList()..sort();
      return <String, Object?>{for (final key in keys) key: _sort(value[key])};
    }
    if (value is List) return [for (final item in value) _sort(item)];
    return value;
  }

  static Map<String, Object?> _commercialSnapshot(SalesCommercialSnapshotInput snapshot) =>
      <String, Object?>{
        'store': <String, Object?>{
          'storeId': snapshot.store.storeId.trim(),
          'storeCode': snapshot.store.storeCode.trim(),
          'displayName': snapshot.store.displayName.trim(),
        },
        'seller': <String, Object?>{
          'actorId': snapshot.seller.actorId.trim(),
          'displayName': snapshot.seller.displayName.trim(),
        },
        'customer': snapshot.customer == null
            ? null
            : <String, Object?>{
                'customerId': snapshot.customer!.customerId.trim(),
                'displayName': snapshot.customer!.displayName.trim(),
                'phoneNumber': _trimToNull(snapshot.customer!.phoneNumber),
                'taxCode': _trimToNull(snapshot.customer!.taxCode),
              },
        'lines': [
          for (final line in snapshot.lines)
            <String, Object?>{
              'lineId': line.lineId.trim(),
              'product': <String, Object?>{
                'productId': line.product.productId.trim(),
                'sku': _trimToNull(line.product.sku),
                'displayName': line.product.displayName.trim(),
              },
              'unit': <String, Object?>{
                'productUnitId': line.unit.productUnitId.trim(),
                'unitCode': _trimToNull(line.unit.unitCode),
                'unitName': line.unit.unitName.trim(),
              },
              'quantityMicros': line.quantity.quantityMicros,
              'unitPrice': _moneyPayload(line.unitPrice),
              'discountTotal': _moneyPayload(line.discountTotal),
              'lineTotal': _moneyPayload(line.lineTotal),
            },
        ],
      };

  static Map<String, Object?> _moneyPayload(MoneyDto money) => <String, Object?>{
    'amountMinor': money.amountMinor,
    'currencyCode': money.currencyCode.trim().toUpperCase(),
  };

  static String? _trimToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day);
  }

  static String? _dateOnlyPayload(DateTime? value) {
    final date = _dateOnly(value);
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
