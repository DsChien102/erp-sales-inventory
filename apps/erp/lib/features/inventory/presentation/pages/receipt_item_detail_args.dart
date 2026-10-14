import '../../data/models/receipt_item_draft.dart';

class ReceiptItemDetailArgs {
  const ReceiptItemDetailArgs({required this.item, this.readOnly = false});

  final ReceiptItemDraft item;
  final bool readOnly;
}
