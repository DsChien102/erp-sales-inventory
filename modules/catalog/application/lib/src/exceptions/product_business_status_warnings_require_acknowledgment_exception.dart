import 'package:vet45_shared_application/application.dart';

import '../lifecycle/product_business_status_warning_dto.dart';

final class ProductBusinessStatusWarningsRequireAcknowledgmentException
    extends ApplicationException {
  ProductBusinessStatusWarningsRequireAcknowledgmentException({
    required this.warnings,
    String? message,
  }) : super(
         message ?? 'Sản phẩm có cảnh báo trước khi ngừng kinh doanh. Xác nhận để tiếp tục.',
       );

  final List<ProductBusinessStatusWarningDto> warnings;
}
