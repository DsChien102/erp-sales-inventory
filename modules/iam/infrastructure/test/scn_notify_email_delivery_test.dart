import 'package:get_it/get_it.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_iam_integration_events/integration_events.dart';
import 'package:vet45_resend/vet45_resend.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  group('scn_notify email delivery (outbox → inbox → internal)', () {
    late InMemoryIamOutboxClient outbox;
    late InMemoryIamInboxClient inbox;
    late InMemoryIamInternalCommands internal;
    late InMemoryEmailDeliveryOutcomeStore outcomes;
    late FakeResendClient resend;
    late InMemoryEventBusClient eventsBus;

    setUp(() {
      IntegrationEventTypeRegistry.clear();
      outbox = InMemoryIamOutboxClient();
      inbox = InMemoryIamInboxClient();
      outcomes = InMemoryEmailDeliveryOutcomeStore();
      resend = FakeResendClient();
      eventsBus = InMemoryEventBusClient();

      final serializer = createGeneratedIamInternalCommandSerializer();
      internal = InMemoryIamInternalCommands(serializer: serializer);

      final container = GetIt.asNewInstance();
      container
        ..registerSingleton<IPasswordResetCodeGateway>(
          _NullPasswordResetCodeGateway(),
        )
        ..registerSingleton<IEmailSenderGateway>(
          IamEmailSenderGateway(
            resendClient: resend,
            codeGateway: container.get<IPasswordResetCodeGateway>(),
          ),
        )
        ..registerSingleton<IEmailDeliveryOutcomeStore>(outcomes)
        ..registerFactory(
          () => SendEmailDeliveryCommandHandler(
            emailSender: container.get<IEmailSenderGateway>(),
            outcomes: container.get<IEmailDeliveryOutcomeStore>(),
          ),
        );

      final bus = CommandBus(container: container);
      CommandsExecutor.bind(bus);

      bus.register<SendEmailDeliveryCommand, void>(
        (command) =>
            container.get<SendEmailDeliveryCommandHandler>().handle(command),
      );

      final eventTypeMapper = OutboxModule.createDefault().mapper;
      final integrationDispatcher = IamIntegrationEventDispatcher()
        ..register(
          EmailDeliveryRequestedIntegrationEventHandler(
            commandScheduler: internal,
          ),
        );

      bus.register<ProcessOutboxCommand, bool>(
        (command) => ProcessOutboxCommandHandler(
          outboxClient: outbox,
          eventTypeMapper: eventTypeMapper,
          eventsBus: eventsBus,
        ).handle(command),
      );
      bus.register<ProcessInboxCommand, bool>(
        (command) => ProcessInboxCommandHandler(
          inboxClient: inbox,
          integrationEventDispatcher: integrationDispatcher,
        ).handle(command),
      );
      bus.register<ProcessInternalCommandsCommand, bool>(
        (command) => ProcessInternalCommandsCommandHandler(
          commandClient: internal,
          serializer: serializer,
        ).handle(command),
      );

      IntegrationEventTypeRegistry.registerAll(
        IamIntegrationEventRegistry.eventTypes,
      );
      eventsBus.subscribe(
        IamIntegrationEventGenericHandler<EmailDeliveryRequestedIntegrationEvent>(
          inboxClient: inbox,
        ),
      );
    });

    tearDown(IntegrationEventTypeRegistry.clear);

    /// Simulates mutation RPC: enqueue_outbox_message + record queued outcome.
    Future<({String messageId, String outcomeId})> seedRpcOutbox({
      required String tenantId,
      required String correlationId,
      String? appLinkUrl,
      Map<String, String> refs = const <String, String>{},
    }) async {
      final messageId = const Uuid().v4();
      final outcomeId = const Uuid().v4();
      final occurredOn = DateTime.now().toUtc();
      final event = EmailDeliveryRequestedIntegrationEvent(
        id: messageId,
        occurredOn: occurredOn,
        tenantId: tenantId,
        templateId: EmailTemplateId.tenantInvitation.wireValue,
        toEmail: 'invitee@example.com',
        correlationId: correlationId,
        outcomeId: outcomeId,
        appLinkUrl: appLinkUrl,
        refs: refs,
      );
      outbox.seed(
        tenantId: tenantId,
        eventType: EmailDeliveryConstants.outboxEventType,
        payload: event.toPayload(),
        messageId: messageId,
        occurredAt: occurredOn,
      );
      await outcomes.record(
        id: outcomeId,
        correlationId: correlationId,
        templateId: EmailTemplateId.tenantInvitation,
        status: EmailDeliveryStatus.queued,
        tenantId: tenantId,
        toEmailMasked: 'i***@example.com',
      );
      return (messageId: messageId, outcomeId: outcomeId);
    }

    test('scn_notify_01 RPC-seeded outbox then process once yields sent', () async {
      resend.scenario = FakeResendScenario.sentOk;
      const tenantId = '11111111-1111-1111-1111-111111111111';
      const correlationId = 'corr-notify-01';

      await seedRpcOutbox(
        tenantId: tenantId,
        correlationId: correlationId,
        appLinkUrl: 'https://app.example.com/i/opaque',
        refs: const <String, String>{'invitation_id': 'inv-1'},
      );
      expect(outbox.messages, hasLength(1));

      final result = await IamStartup.processMessagingOnce(tenantId: tenantId);
      expect(result.hadOutboxWork, isTrue);
      expect(result.hadInboxWork, isTrue);
      expect(result.hadInternalWork, isTrue);
      expect(resend.sendCount, 1);

      final outcome = await outcomes.getByCorrelationId(correlationId);
      expect(outcome, isNotNull);
      expect(outcome!.status, EmailDeliveryStatus.sent);
      expect(outcome.providerMessageId, startsWith('re_fake_'));
      expect(internal.failedErrors, isEmpty);
      expect(outbox.failedErrors, isEmpty);
      expect(inbox.failedErrors, isEmpty);
    });

    test('scn_notify_02 resend fail yields failed and internal fail', () async {
      resend.scenario = FakeResendScenario.failed;
      const tenantId = '22222222-2222-2222-2222-222222222222';
      const correlationId = 'corr-notify-02';

      await seedRpcOutbox(tenantId: tenantId, correlationId: correlationId);

      final result = await IamStartup.processMessagingOnce(tenantId: tenantId);
      expect(result.hadInternalWork, isTrue);

      final outcome = await outcomes.getByCorrelationId(correlationId);
      expect(outcome!.status, EmailDeliveryStatus.failed);
      expect(outcome.error, 'resend_5xx');
      expect(internal.failedErrors, isNotEmpty);
    });
  });
}

/// Stub gateway: always returns null (no password-reset ops in notification tests).
final class _NullPasswordResetCodeGateway implements IPasswordResetCodeGateway {
  @override
  Future<String?> peekDeliveryCode(String operationId) async => null;
}
