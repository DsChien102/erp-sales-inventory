import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('DeliveryDisplayStatePolicy', () {
    test('no history projects NOT_SENT', () {
      final projection = DeliveryDisplayStatePolicy.project(const []);

      expect(projection.displayState, DeliveryDisplayState.notSent);
      expect(projection.hasSecondaryAttention, isFalse);
    });

    test('processing without success projects SENDING', () {
      expect(
        DeliveryDisplayStatePolicy.project([
          DeliveryStatus.processing,
        ]).displayState,
        DeliveryDisplayState.sending,
      );
      expect(
        DeliveryDisplayStatePolicy.project([
          DeliveryStatus.failed,
          DeliveryStatus.processing,
        ]).displayState,
        DeliveryDisplayState.sending,
      );
      expect(
        DeliveryDisplayStatePolicy.project([
          DeliveryStatus.processing,
        ]).hasSecondaryAttention,
        isFalse,
      );
    });

    test('th08_s5 first unknown is displayed as unknown', () {
      final result = DeliveryDisplayStatePolicy.project([
        DeliveryStatus.unknown,
      ]);

      expect(result.displayState, DeliveryDisplayState.unknown);
      expect(result.hasSecondaryAttention, isFalse);
    });

    test('failed then unknown without success projects UNKNOWN', () {
      final result = DeliveryDisplayStatePolicy.project([
        DeliveryStatus.failed,
        DeliveryStatus.unknown,
      ]);

      expect(result.displayState, DeliveryDisplayState.unknown);
      expect(result.hasSecondaryAttention, isFalse);
    });

    test('latest failure without success projects FAILED', () {
      final projection = DeliveryDisplayStatePolicy.project([
        DeliveryStatus.failed,
      ]);

      expect(projection.displayState, DeliveryDisplayState.failed);
      expect(projection.hasSecondaryAttention, isFalse);
    });

    test('any success projects SENT', () {
      final projection = DeliveryDisplayStatePolicy.project([
        DeliveryStatus.succeeded,
      ]);

      expect(projection.displayState, DeliveryDisplayState.sent);
      expect(projection.hasSecondaryAttention, isFalse);
    });

    test('th08_s5 prior success remains sent when latest resend is unknown', () {
      final result = DeliveryDisplayStatePolicy.project([
        DeliveryStatus.succeeded,
        DeliveryStatus.unknown,
      ]);

      expect(result.displayState, DeliveryDisplayState.sent);
      expect(result.hasSecondaryAttention, isTrue);
    });

    test(
      'failed or unknown resend after success keeps SENT with secondary attention',
      () {
        final afterFailure = DeliveryDisplayStatePolicy.project([
          DeliveryStatus.succeeded,
          DeliveryStatus.failed,
        ]);
        expect(afterFailure.displayState, DeliveryDisplayState.sent);
        expect(afterFailure.hasSecondaryAttention, isTrue);

        final afterUnknown = DeliveryDisplayStatePolicy.project([
          DeliveryStatus.succeeded,
          DeliveryStatus.unknown,
        ]);
        expect(afterUnknown.displayState, DeliveryDisplayState.sent);
        expect(afterUnknown.hasSecondaryAttention, isTrue);
      },
    );
  });
}
