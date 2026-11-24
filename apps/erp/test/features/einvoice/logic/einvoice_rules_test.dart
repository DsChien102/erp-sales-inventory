import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/logic/einvoice_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EInvoiceRules', () {
    const validUuid = '11111111-1111-4111-8111-111111111111';

    void expectValidation(void Function() call, String expectedMessage) {
      expect(
        call,
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', EInvoiceErrorCodes.validationError)
              .having((e) => e.serverMessage, 'serverMessage', expectedMessage),
        ),
      );
    }

    group('checkConnect', () {
      test('valid: username and password non-empty (password with whitespace not trimmed)', () {
        expect(
          () => EInvoiceRules.checkConnect(username: 'misa', password: ' '),
          returnsNormally,
        );
      });

      test('invalid: empty username', () {
        expectValidation(
          () => EInvoiceRules.checkConnect(username: '   ', password: 'secret'),
          'username is required',
        );
      });

      test('invalid: empty password', () {
        expectValidation(
          () => EInvoiceRules.checkConnect(username: 'misa', password: ''),
          'password is required',
        );
      });
    });

    group('checkSetDefaultConfiguration', () {
      test('valid: non-empty ids', () {
        expect(
          () => EInvoiceRules.checkSetDefaultConfiguration(
            templateId: 'tpl-1',
            signingConfigId: 'sign-1',
          ),
          returnsNormally,
        );
      });

      test('invalid: empty templateId', () {
        expectValidation(
          () => EInvoiceRules.checkSetDefaultConfiguration(
            templateId: '  ',
            signingConfigId: 'sign-1',
          ),
          'templateId is required',
        );
      });

      test('invalid: empty signingConfigId', () {
        expectValidation(
          () => EInvoiceRules.checkSetDefaultConfiguration(
            templateId: 'tpl-1',
            signingConfigId: '   ',
          ),
          'signingConfigId is required',
        );
      });
    });

    group('checkUpdateAutomationPolicy', () {
      test('valid: version >= 0 and at least one flag', () {
        expect(
          () => EInvoiceRules.checkUpdateAutomationPolicy(
            expectedPolicyVersion: 0,
            autoIssueEnabled: true,
          ),
          returnsNormally,
        );
        expect(
          () => EInvoiceRules.checkUpdateAutomationPolicy(
            expectedPolicyVersion: 2,
            autoSendEnabled: false,
          ),
          returnsNormally,
        );
      });

      test('invalid: negative version', () {
        expectValidation(
          () => EInvoiceRules.checkUpdateAutomationPolicy(
            expectedPolicyVersion: -1,
            autoIssueEnabled: true,
          ),
          'expectedPolicyVersion must be non-negative',
        );
      });

      test('invalid: both flags null', () {
        expectValidation(
          () => EInvoiceRules.checkUpdateAutomationPolicy(
            expectedPolicyVersion: 1,
            autoIssueEnabled: null,
            autoSendEnabled: null,
          ),
          'At least one of autoIssueEnabled or autoSendEnabled must be set',
        );
      });
    });

    group('checkSalesOrderId', () {
      test('valid: non-empty salesOrderId', () {
        expect(
          () => EInvoiceRules.checkSalesOrderId('order-1'),
          returnsNormally,
        );
      });

      test('invalid: empty salesOrderId', () {
        expectValidation(
          () => EInvoiceRules.checkSalesOrderId('   '),
          'salesOrderId is required',
        );
      });
    });

    group('checkIssue', () {
      test('valid params', () {
        expect(
          () => EInvoiceRules.checkIssue(
            salesOrderId: 'order-1',
            sourceVersion: 'v1',
            idempotencyKey: validUuid,
          ),
          returnsNormally,
        );
      });

      test('invalid: empty salesOrderId', () {
        expectValidation(
          () => EInvoiceRules.checkIssue(
            salesOrderId: ' ',
            sourceVersion: 'v1',
            idempotencyKey: validUuid,
          ),
          'salesOrderId is required',
        );
      });

      test('invalid: empty sourceVersion', () {
        expectValidation(
          () => EInvoiceRules.checkIssue(
            salesOrderId: 'order-1',
            sourceVersion: ' ',
            idempotencyKey: validUuid,
          ),
          'sourceVersion is required',
        );
      });

      test('invalid: non-UUID key', () {
        expectValidation(
          () => EInvoiceRules.checkIssue(
            salesOrderId: 'order-1',
            sourceVersion: 'v1',
            idempotencyKey: 'abc',
          ),
          'idempotencyKey must be a canonical UUID',
        );
      });
    });

    group('checkRetry', () {
      test('valid params', () {
        expect(
          () => EInvoiceRules.checkRetry(
            salesOrderId: 'order-1',
            expectedOrderVersion: 1,
            idempotencyKey: validUuid,
          ),
          returnsNormally,
        );
      });

      test('invalid: version <= 0', () {
        expectValidation(
          () => EInvoiceRules.checkRetry(
            salesOrderId: 'order-1',
            expectedOrderVersion: 0,
            idempotencyKey: validUuid,
          ),
          'expectedOrderVersion must be positive',
        );
      });

      test('invalid: non-UUID key', () {
        expectValidation(
          () => EInvoiceRules.checkRetry(
            salesOrderId: 'order-1',
            expectedOrderVersion: 1,
            idempotencyKey: 'not-a-uuid',
          ),
          'idempotencyKey must be a canonical UUID',
        );
      });
    });

    group('checkSend', () {
      test('valid: trimmed valid email and UUID', () {
        expect(
          () => EInvoiceRules.checkSend(
            salesOrderId: 'order-1',
            recipientEmail: ' a@b.vn ',
            idempotencyKey: validUuid,
          ),
          returnsNormally,
        );
      });

      test('invalid: malformed email', () {
        expectValidation(
          () => EInvoiceRules.checkSend(
            salesOrderId: 'order-1',
            recipientEmail: 'a@b',
            idempotencyKey: validUuid,
          ),
          'Delivery recipient email must be a valid address',
        );
      });

      test('invalid: non-UUID key', () {
        expectValidation(
          () => EInvoiceRules.checkSend(
            salesOrderId: 'order-1',
            recipientEmail: 'user@example.com',
            idempotencyKey: 'abc',
          ),
          'idempotencyKey must be a canonical UUID',
        );
      });
    });
  });
}

