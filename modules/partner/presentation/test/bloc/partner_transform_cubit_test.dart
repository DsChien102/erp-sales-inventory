import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  late FakeExecutionContext executionContext;

  setUp(() {
    executionContext = FakeExecutionContext(
      tenantId: 'tenant-1',
      userId: 'user-1',
    );
  });

  test('confirmTransform dispatches TransformPersonToOrganizationCommand', () async {
    final module = _RecordingPartnerModule();
    final cubit = PartnerTransformCubit(
      partnerModule: module,
      executionContext: executionContext,
    );

    await cubit.confirmTransform(
      partnerId: 'p-1',
      expectedVersion: 3,
      organizationProfile: const OrganizationProfileInput(
        organizationType: OrganizationType.company,
        organizationName: 'Công ty TNHH An Phát',
        phone: '02838225511',
      ),
    );

    final command = module.commands.single as TransformPersonToOrganizationCommand;
    expect(command.tenantId, 'tenant-1');
    expect(command.actorId, 'user-1');
    expect(command.partnerId, 'p-1');
    expect(command.expectedVersion, 3);
    expect(command.organizationProfile.organizationName, 'Công ty TNHH An Phát');
    expect(cubit.state.status, PartnerTransformSubmitStatus.success);
    expect(cubit.state.transformedPartnerId, 'p-1');
  });

  test('maps NO_PERMISSION to blocked noPermission', () async {
    final cubit = PartnerTransformCubit(
      partnerModule: FakePartnerModule(
        scenario: FakePartnerScenario.transformPermissionDenied,
      ),
      executionContext: executionContext,
    );

    await cubit.confirmTransform(
      partnerId: 'p-1',
      expectedVersion: 1,
      organizationProfile: const OrganizationProfileInput(
        organizationType: OrganizationType.company,
        organizationName: 'Công ty A',
        phone: '02838225511',
      ),
    );

    expect(cubit.state.status, PartnerTransformSubmitStatus.blocked);
    expect(cubit.state.blocked, PartnerTransformBlockedKind.noPermission);
  });

  test('maps STATE_CHANGED to blocked staleData', () async {
    final cubit = PartnerTransformCubit(
      partnerModule: FakePartnerModule(
        scenario: FakePartnerScenario.transformStateChanged,
      ),
      executionContext: executionContext,
    );

    await cubit.confirmTransform(
      partnerId: 'p-1',
      expectedVersion: 1,
      organizationProfile: const OrganizationProfileInput(
        organizationType: OrganizationType.company,
        organizationName: 'Công ty A',
        phone: '02838225511',
      ),
    );

    expect(cubit.state.status, PartnerTransformSubmitStatus.blocked);
    expect(cubit.state.blocked, PartnerTransformBlockedKind.staleData);
  });

  test('maps DUPLICATE_WARNING to friendly duplicate status', () async {
    final cubit = PartnerTransformCubit(
      partnerModule: FakePartnerModule(
        scenario: FakePartnerScenario.transformDupWarning,
      ),
      executionContext: executionContext,
    );

    await cubit.confirmTransform(
      partnerId: 'p-1',
      expectedVersion: 1,
      organizationProfile: const OrganizationProfileInput(
        organizationType: OrganizationType.company,
        organizationName: 'Công ty A',
        phone: '0981287110',
      ),
    );

    expect(cubit.state.status, PartnerTransformSubmitStatus.duplicate);
    expect(
      cubit.state.generalError,
      PartnerTransformCubit.duplicateUserMessage,
    );
    expect(cubit.state.fieldErrors['phone'], PartnerTransformCubit.duplicatePhoneMessage);
    expect(cubit.state.generalError, isNot(contains('PostgrestException')));
  });

  test('parseDuplicateFieldErrors maps phone email tax_code', () {
    const raw =
        '[{"code":"DUPLICATE_WARNING","field":"email"},'
        '{"code":"DUPLICATE_WARNING","field":"tax_code"}]';
    final errors = PartnerTransformCubit.parseDuplicateFieldErrors(raw);
    expect(errors['email'], PartnerTransformCubit.duplicateEmailMessage);
    expect(errors['taxCode'], PartnerTransformCubit.duplicateTaxCodeMessage);
    expect(errors.containsKey('phone'), isFalse);
  });
}

final class _RecordingPartnerModule implements IPartnerModule {
  final commands = <ICommand<Object?>>[];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command as ICommand<Object?>);
    if (command is TransformPersonToOrganizationCommand) {
      final transform = command as TransformPersonToOrganizationCommand;
      return TransformPartnerResult(partnerId: transform.partnerId) as TResult;
    }
    throw UnsupportedError(command.runtimeType.toString());
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnsupportedError(query.runtimeType.toString());
  }
}
