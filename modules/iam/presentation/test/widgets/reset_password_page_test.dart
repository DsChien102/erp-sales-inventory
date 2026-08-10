import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_iam_presentation/testing.dart';
import 'package:vet45_shared_application/application.dart';

/// Local scripted delegate for Cubit unit tests (ScriptedIamModule not in package).
final class _ScriptedIamModule implements IIamModule {
  _ScriptedIamModule({
    required this.onCommand,
    required this.onQuery,
  });

  final Future<Object?> Function(Object message) onCommand;
  final Future<Object?> Function(Object message) onQuery;

  @override
  Future<TResult> executeCommandAsync<TResult>(
    ICommand<TResult> command,
  ) async {
    return await onCommand(command) as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    return await onQuery(query) as TResult;
  }
}

final class _RecordingPageIamModule implements IIamModule {
  _RecordingPageIamModule({
    this.verifyResult = true,
    this.resendAvailableAfter = const Duration(seconds: 2),
  });

  final bool verifyResult;
  final Duration resendAvailableAfter;
  final List<Type> commandTypes = <Type>[];
  DateTime Function() clock = DateTime.now;

  @override
  Future<TResult> executeCommandAsync<TResult>(
    ICommand<TResult> command,
  ) async {
    commandTypes.add(command.runtimeType);
    final now = clock().toUtc();
    return switch (command) {
      RequestMyPasswordResetCommand() =>
        PasswordResetRequestResultDto(
              operationId: 'op-1',
              maskedEmail: 'l***@example.com',
              expiresAt: now.add(const Duration(minutes: 10)),
              resendAvailableAt: now.add(resendAvailableAfter),
            )
            as TResult,
      ResendMyPasswordResetCommand() =>
        PasswordResetRequestResultDto(
              operationId: 'op-1',
              maskedEmail: 'l***@example.com',
              expiresAt: now.add(const Duration(minutes: 10)),
              resendAvailableAt: now.add(const Duration(seconds: 3)),
            )
            as TResult,
      VerifyMyPasswordResetCommand() =>
        PasswordResetVerifyResultDto(verified: verifyResult) as TResult,
      CompleteMyPasswordResetCommand() =>
        const PasswordResetCompletionResultDto(
              currentSessionRotated: true,
              otherSessionsRevoked: true,
            )
            as TResult,
      _ => throw UnsupportedError('${command.runtimeType}'),
    };
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnsupportedError('${query.runtimeType}');
  }
}

Future<void> _settleRequest(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  group('PasswordResetCubit', () {
    test('failed initial request retries Request command', () async {
      var requestCount = 0;
      final scripted = _ScriptedIamModule(
        onCommand: (message) async {
          if (message is RequestMyPasswordResetCommand) {
            requestCount += 1;
            if (requestCount == 1) {
              throw const IamBlockedException(IamBlockedCodes.systemError);
            }
            return PasswordResetRequestResultDto(
              operationId: 'reset-op-1',
              maskedEmail: 'l***@example.com',
              expiresAt: DateTime.utc(2026, 7, 31, 9, 10),
              resendAvailableAt: DateTime.utc(2026, 7, 31, 9, 1),
            );
          }
          throw UnsupportedError(message.runtimeType.toString());
        },
        onQuery: (message) async => throw UnsupportedError(message.runtimeType.toString()),
      );
      final module = RecordingIamModule(scripted);
      final cubit = PasswordResetCubit(
        iamModule: module,
        clock: () => DateTime.utc(2026, 7, 31, 9),
      );
      await cubit.request();
      await cubit.retry();
      expect(module.commandsOf<RequestMyPasswordResetCommand>(), hasLength(2));
      expect(module.commandsOf<ResendMyPasswordResetCommand>(), isEmpty);
      await cubit.close();
    });

    test('resend uses operationId returned by request', () async {
      final scripted = _ScriptedIamModule(
        onCommand: (message) async {
          if (message is RequestMyPasswordResetCommand || message is ResendMyPasswordResetCommand) {
            return PasswordResetRequestResultDto(
              operationId: 'reset-op-1',
              maskedEmail: 'l***@example.com',
              expiresAt: DateTime.utc(2026, 7, 31, 9, 10),
              resendAvailableAt: DateTime.utc(2026, 7, 31, 9),
            );
          }
          throw UnsupportedError(message.runtimeType.toString());
        },
        onQuery: (message) async => throw UnsupportedError(message.runtimeType.toString()),
      );
      final module = RecordingIamModule(scripted);
      final cubit = PasswordResetCubit(
        iamModule: module,
        clock: () => DateTime.utc(2026, 7, 31, 9),
      );
      await cubit.request();
      await cubit.resend();
      final command = module.commandsOf<ResendMyPasswordResetCommand>().single;
      expect(command.operationId, 'reset-op-1');
      await cubit.close();
    });
  });

  testWidgets(
    'ResetPasswordPage requests reset, shows countdown, then resends',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var now = DateTime.utc(2026, 7, 31, 9);
      final module = _RecordingPageIamModule();
      module.clock = () => now;

      await tester.pumpWidget(
        MaterialApp(
          home: ResetPasswordPage(
            iamModule: module,
            clock: () => now,
          ),
        ),
      );
      await _settleRequest(tester);

      expect(module.commandTypes, contains(RequestMyPasswordResetCommand));
      expect(
        find.textContaining('Mã 6 chữ số đã được gửi tới l***@example.com'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is VButton && w.label.startsWith('Gửi lại mã sau 00:') && w.onPressed == null,
        ),
        findsOneWidget,
      );

      for (var i = 0; i < 5; i++) {
        now = now.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        if (find.widgetWithText(VButton, 'Gửi lại mã').evaluate().isNotEmpty) {
          break;
        }
      }

      final resendFinder = find.widgetWithText(VButton, 'Gửi lại mã');
      expect(resendFinder, findsOneWidget);
      await tester.tap(resendFinder);
      await _settleRequest(tester);

      expect(module.commandTypes, contains(ResendMyPasswordResetCommand));
      expect(
        find.byWidgetPredicate(
          (w) => w is VButton && w.label.startsWith('Gửi lại mã sau 00:') && w.onPressed == null,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ResetPasswordPage stays on verify when verified=false',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = _RecordingPageIamModule(verifyResult: false);

      await tester.pumpWidget(
        MaterialApp(
          home: ResetPasswordPage(iamModule: module),
        ),
      );
      await _settleRequest(tester);

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      await tester.tap(find.widgetWithText(VButton, 'Xác nhận mã'));
      await _settleRequest(tester);

      expect(module.commandTypes, contains(VerifyMyPasswordResetCommand));
      expect(find.text('Xác minh email'), findsOneWidget);
      expect(find.text('Tạo mật khẩu mới'), findsNothing);
    },
  );

  testWidgets(
    'ResetPasswordPage advances when verified=true',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = _RecordingPageIamModule();

      await tester.pumpWidget(
        MaterialApp(
          home: ResetPasswordPage(iamModule: module),
        ),
      );
      await _settleRequest(tester);

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      await tester.tap(find.widgetWithText(VButton, 'Xác nhận mã'));
      await _settleRequest(tester);

      expect(module.commandTypes, contains(VerifyMyPasswordResetCommand));
      expect(find.text('Tạo mật khẩu mới'), findsOneWidget);
    },
  );

  testWidgets(
    'ResetPasswordPage completes with typed result and pops true',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = _RecordingPageIamModule();
      Object? popResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    popResult = await Navigator.of(context).push<Object?>(
                      MaterialPageRoute<Object?>(
                        builder: (_) => ResetPasswordPage(iamModule: module),
                      ),
                    );
                  },
                  child: const Text('open-reset'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open-reset'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await _settleRequest(tester);

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      await tester.tap(find.widgetWithText(VButton, 'Xác nhận mã'));
      await _settleRequest(tester);

      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.at(0), 'Password#123');
      await tester.enterText(passwordFields.at(1), 'Password#123');
      await tester.pump();

      await tester.tap(find.widgetWithText(VButton, 'Đặt lại mật khẩu'));
      await _settleRequest(tester);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(
        module.commandTypes.where((t) => t == CompleteMyPasswordResetCommand).length,
        1,
      );
      expect(popResult, isTrue);
      expect(find.textContaining('Password#123'), findsNothing);
      expect(find.text('123456'), findsNothing);
      expect(find.textContaining('op-1'), findsNothing);
    },
  );

  testWidgets(
    'ResetPasswordPage (TA-D-03) offline validation flow without iamModule',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordPage(emailMasked: 'mi***@gmail.com'),
        ),
      );

      expect(find.text('Đặt lại mật khẩu'), findsOneWidget);
      expect(find.text('Xác minh email'), findsOneWidget);
      expect(
        find.textContaining('Mã 6 chữ số đã được gửi tới mi***@gmail.com'),
        findsOneWidget,
      );

      final verifyButtonFinder = find.widgetWithText(VButton, 'Xác nhận mã');
      expect(verifyButtonFinder, findsOneWidget);

      var verifyBtnWidget = tester.widget<VButton>(verifyButtonFinder);
      expect(verifyBtnWidget.onPressed, isNull);

      final codeField = find.byType(TextField);
      await tester.enterText(codeField.first, '123456');
      await tester.pump();

      verifyBtnWidget = tester.widget<VButton>(verifyButtonFinder);
      expect(verifyBtnWidget.onPressed, isNotNull);

      await tester.tap(verifyButtonFinder);
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(find.text('Tạo mật khẩu mới'), findsOneWidget);

      final resetButtonFinder = find.widgetWithText(VButton, 'Đặt lại mật khẩu');
      expect(resetButtonFinder, findsOneWidget);

      var resetBtnWidget = tester.widget<VButton>(resetButtonFinder);
      expect(resetBtnWidget.onPressed, isNull);

      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.at(0), '123');
      await tester.pump();

      resetBtnWidget = tester.widget<VButton>(resetButtonFinder);
      expect(resetBtnWidget.onPressed, isNull);

      await tester.enterText(passwordFields.at(1), '456');
      await tester.pump();

      resetBtnWidget = tester.widget<VButton>(resetButtonFinder);
      expect(resetBtnWidget.onPressed, isNotNull);

      await tester.tap(resetButtonFinder);
      await tester.pump();

      expect(
        find.text(PasswordPolicy.violationMessage),
        findsOneWidget,
      );
      expect(find.text('Mật khẩu nhập lại không trùng khớp'), findsOneWidget);

      await tester.enterText(passwordFields.at(0), 'Password123!');
      await tester.enterText(passwordFields.at(1), 'Password123!');
      await tester.pump();

      expect(find.text(PasswordPolicy.violationMessage), findsNothing);
      expect(find.text('Mật khẩu nhập lại không trùng khớp'), findsNothing);
    },
  );
}
