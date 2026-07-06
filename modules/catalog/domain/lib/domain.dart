/// catalog domain layer — aggregates, value objects, and shared codes.
library;

export 'src/ids/product_id.dart';
export 'src/product/events/product_created.dart';
export 'src/product/product.dart';
export 'src/product/product_base_unit.dart';
export 'src/product/product_image.dart';
export 'src/product/repositories/i_product_duplicate_checker.dart';
export 'src/product/rules/at_most_one_primary_image_rule.dart';
export 'src/product/rules/product_name_required_rule.dart';
export 'src/readiness/product_readiness.dart';
export 'src/readiness/readiness_blocker.dart';
export 'src/readiness/readiness_blocker_code.dart';
export 'src/readiness/readiness_status.dart';
export 'src/shared/catalog_permissions.dart';
export 'src/shared/product_duplicate_field.dart';
export 'src/shared/product_status.dart';
export 'src/value_objects/barcode.dart';
export 'src/value_objects/product_name.dart';
export 'src/value_objects/sku.dart';
