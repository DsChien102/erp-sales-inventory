import 'package:vet45_iam_application/application.dart';

/// In-memory invitation reads for unit/fake tests (S6).
final class FakeTenantInvitationReadPort implements ITenantInvitationReadPort {
  FakeTenantInvitationReadPort({
    List<InvitationDetailDto>? invitations,
  }) : _invitations = List<InvitationDetailDto>.from(invitations ?? const []);

  final List<InvitationDetailDto> _invitations;

  void seed(InvitationDetailDto invitation) => _invitations.add(invitation);

  @override
  Future<CursorPageDto<InvitationSummaryDto>> listInvitations({
    required String tenantId,
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    var rows = _invitations.toList(growable: false);
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      rows = rows
          .where((i) => i.inviteeEmail.toLowerCase().contains(q))
          .toList(growable: false);
    }
    if (status != null && status.isNotEmpty) {
      rows = rows.where((i) => i.status == status).toList(growable: false);
    }
    final page = rows.take(limit).map((i) => i.toSummary()).toList(growable: false);
    return CursorPageDto<InvitationSummaryDto>(
      items: page,
      nextCursor: rows.length > limit ? 'next' : null,
    );
  }

  @override
  Future<InvitationDetailDto?> getInvitation({
    required String tenantId,
    required String invitationId,
  }) async {
    for (final row in _invitations) {
      if (row.invitationId == invitationId) {
        return row;
      }
    }
    return null;
  }
}
