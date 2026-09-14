import 'package:vet45_sales_application/application.dart';

/// Performs a receipt operation at the device boundary after the receipt has
/// been loaded from the Sales module.
typedef SalesReceiptDeviceAction = Future<void> Function(SalesReceiptDocumentDto document);
