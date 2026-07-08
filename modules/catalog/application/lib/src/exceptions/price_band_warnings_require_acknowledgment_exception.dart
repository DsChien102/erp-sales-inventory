import 'package:vet45_shared_application/application.dart';

import '../pricing/price_band/price_band_validation_warning_dto.dart';

final class PriceBandWarningsRequireAcknowledgmentException extends ApplicationException {
  PriceBandWarningsRequireAcknowledgmentException({
    required this.warnings,
    String? message,
  }) : super(
          message ??
              'Khung giá có cảnh báo so với Giá cơ sở. Xác nhận để tiếp tục lưu.',
        );

  final List<PriceBandValidationWarningDto> warnings;
}
