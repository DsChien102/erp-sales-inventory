import '../dto/cursor_page_dto.dart';
import '../invitation/shared/invitation_detail_dto.dart';
import '../invitation/shared/invitation_summary_dto.dart';

/// Read port for tenant invitations (S6 list/detail).
abstract interface class ITenantInvitationReadPort {
  Future<CursorPageDto<InvitationSummaryDto>> listInvitations({
    required String tenantId,
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  });

  Future<InvitationDetailDto?> getInvitation({
    required String tenantId,
    required String invitationId,
  });
}
