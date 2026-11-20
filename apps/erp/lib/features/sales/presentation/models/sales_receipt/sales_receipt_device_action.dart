import 'package:erp/features/sales/data/models.dart';

/// Performs a receipt operation at the device boundary after the receipt has
/// been loaded from the Sales module.
typedef SalesReceiptDeviceAction = Future<void> Function(SalesReceiptDocumentDto document);
