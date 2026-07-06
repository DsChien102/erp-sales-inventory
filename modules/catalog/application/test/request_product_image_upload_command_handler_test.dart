import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

class _RecordingUploadPort implements IProductImageUploadPort {
  RequestProductImageUploadCommand? lastCommand;

  @override
  Future<ProductImageUploadSlotDto> reserveUploadSlot(
    RequestProductImageUploadCommand command,
  ) async {
    lastCommand = command;
    return ProductImageUploadSlotDto(
      slotId: 'slot-1',
      storageKey: '${command.tenantId}/staging/slot-1/original.jpeg',
      signedUploadUrl: 'https://storage.example/upload',
      expiresAt: DateTime.utc(2026, 7, 5, 12),
    );
  }
}

void main() {
  group('RequestProductImageUploadCommandHandler', () {
    test('reserves upload slot via port', () async {
      final port = _RecordingUploadPort();
      final handler = RequestProductImageUploadCommandHandler(uploadPort: port);

      final result = await handler.handle(
        RequestProductImageUploadCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          fileName: 'photo.jpg',
          contentType: 'image/jpeg',
          byteSize: 1024,
        ),
      );

      expect(port.lastCommand?.fileName, 'photo.jpg');
      expect(result.slotId, 'slot-1');
      expect(result.storageKey, contains('staging'));
      expect(result.signedUploadUrl, isNotEmpty);
    });
  });

  group('RequestProductImageUploadCommandValidator', () {
    final validator = RequestProductImageUploadCommandValidator();

    test('rejects unsupported content type', () async {
      expect(
        () => validator.validate(
          RequestProductImageUploadCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            fileName: 'photo.gif',
            contentType: 'image/gif',
            byteSize: 1024,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
