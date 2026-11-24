import 'sales_order_draft_dto.dart';

final class SalesOrderDraftForRestoreDto {
  SalesOrderDraftForRestoreDto({
    required this.draft,
    required this.savedAt,
    required this.savedByActorId,
  }) : assert(
         savedAt == draft.savedAt,
         'savedAt must equal draft.savedAt',
       ),
       assert(
         savedByActorId == draft.savedByActorId,
         'savedByActorId must equal draft.savedByActorId',
       );

  final SalesOrderDraftDto draft;
  final DateTime savedAt;
  final String savedByActorId;
}
