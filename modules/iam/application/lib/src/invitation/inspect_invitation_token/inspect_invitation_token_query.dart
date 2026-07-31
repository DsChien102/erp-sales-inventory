import 'package:vet45_shared_application/application.dart';

import '../shared/invitation_token_inspection_dto.dart';

/// Inspect opaque invitation token without consuming it (§S8).
@PublicAccess()
final class InspectInvitationTokenQuery
    extends QueryBase<InvitationTokenInspectionDto>
    implements IQuery<InvitationTokenInspectionDto> {
  InspectInvitationTokenQuery({
    String? id,
    required this.token,
  }) : super(id);

  final String token;
}
