import 'package:vet45_shared_application/application.dart';

final class ProductConversionUnitDeleteBlockedException extends ApplicationException {
  ProductConversionUnitDeleteBlockedException({
    String? message,
  }) : super(
         message ??
             'Không thể xóa đơn vị này vì đã có dữ liệu phụ thuộc. '
                 'Hãy dùng "Tắt đơn vị" để bảo toàn lịch sử.',
       );

  static const suggestDeactivateActionId = 'deactivate_conversion_unit';
}
