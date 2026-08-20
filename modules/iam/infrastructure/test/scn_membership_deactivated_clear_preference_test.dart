import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_iam_integration_events/integration_events.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

class _InMemoryPreferencePort implements IPlatformUserPreferencePort {
  String? _lastSelected;

  String? get lastSelected => _lastSelected;

  @override
  Future<String?> getLastSelectedTenantId() async => _lastSelected;

  @override
  Future<void> setLastSelectedTenantId(String? tenantId) async {
    _lastSelected = tenantId;
  }
}

void main() {
  group('scn_membership_deactivated outbox → inbox → clear preference', () {
    late InMemoryIamOutboxClient outbox;
    late InMemoryIamInboxClient inbox;
    late _InMemoryPreferencePort preferencePort;
    late InMemoryEventBusClient eventsBus;
    late ProcessOutboxCommandHandler processOutboxHandler;
    late ProcessInboxCommandHandler processInboxHandler;

    const tenantId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

    setUp(() {
      IntegrationEventTypeRegistry.clear();
      outbox = InMemoryIamOutboxClient();
      inbox = InMemoryIamInboxClient();
      preferencePort = _InMemoryPreferencePort();
      eventsBus = InMemoryEventBusClient();

      // serializer not needed for this pipeline (no internal commands)
      final _ = createGeneratedIamInternalCommandSerializer();

      final integrationDispatcher = IamIntegrationEventDispatcher()
        ..register(
          MembershipDeactivatedIntegrationEventHandler(
            preferencePort: preferencePort,
          ),
        );

      final eventTypeMapper = OutboxModule.createDefault().mapper;

      processOutboxHandler = ProcessOutboxCommandHandler(
        outboxClient: outbox,
        eventTypeMapper: eventTypeMapper,
        eventsBus: eventsBus,
      );
      processInboxHandler = ProcessInboxCommandHandler(
        inboxClient: inbox,
        integrationEventDispatcher: integrationDispatcher,
      );

      IntegrationEventTypeRegistry.registerAll(
        IamIntegrationEventRegistry.eventTypes,
      );
      eventsBus.subscribe(
        IamIntegrationEventGenericHandler<MembershipDeactivatedIntegrationEvent>(
          inboxClient: inbox,
        ),
      );
    });

    tearDown(IntegrationEventTypeRegistry.clear);

    Future<String> seedOutbox({
      required String membershipId,
      required String userId,
    }) async {
      final messageId = const Uuid().v4();
      final occurredOn = DateTime.now().toUtc();
      final event = MembershipDeactivatedIntegrationEvent(
        id: messageId,
        occurredOn: occurredOn,
        tenantId: tenantId,
        membershipId: membershipId,
        userId: userId,
        version: 2,
        actorUserId: const Uuid().v4(),
      );
      outbox.seed(
        tenantId: tenantId,
        eventType: MembershipDeactivatedIntegrationEvent.type,
        payload: event.toPayload(),
        messageId: messageId,
        occurredAt: occurredOn,
      );
      return messageId;
    }

    test(
      'scn_deactivated_01 outbox seeded → process once → preference cleared',
      () async {
        // Arrange: user previously selected this tenant
        await preferencePort.setLastSelectedTenantId(tenantId);
        expect(preferencePort.lastSelected, tenantId);

        await seedOutbox(
          membershipId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          userId: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
        );
        expect(outbox.messages, hasLength(1));

        // Act: drive outbox → EventsBus → inbox pipeline
        final hadOutbox = await processOutboxHandler.handle(
          ProcessOutboxCommand(tenantId: tenantId),
        );
        expect(hadOutbox, isTrue);

        // EventsBus delivered event → inbox received message
        expect(inbox.messages, hasLength(1));

        final hadInbox = await processInboxHandler.handle(
          ProcessInboxCommand(tenantId: tenantId),
        );
        expect(hadInbox, isTrue);

        // Assert: preference was cleared
        expect(preferencePort.lastSelected, isNull);
        expect(outbox.failedErrors, isEmpty);
        expect(inbox.failedErrors, isEmpty);
      },
    );

    test(
      'scn_deactivated_02 no outbox messages → preference untouched',
      () async {
        await preferencePort.setLastSelectedTenantId(tenantId);

        final hadOutbox = await processOutboxHandler.handle(
          ProcessOutboxCommand(tenantId: tenantId),
        );
        expect(hadOutbox, isFalse);
        expect(preferencePort.lastSelected, tenantId);
      },
    );
  });
}
