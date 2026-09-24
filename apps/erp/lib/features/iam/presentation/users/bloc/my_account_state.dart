import 'package:vet45_iam_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/iam_ui_failure.dart';

final class MyAccountState {
  const MyAccountState({
    this.status = IamLoadStatus.initial,
    this.profile,
    this.failure,
    this.isOwner = false,
  });

  final IamLoadStatus status;
  final MyIdentityProfileDto? profile;
  final IamUiFailure? failure;
  final bool isOwner;

  MyAccountState copyWith({
    IamLoadStatus? status,
    MyIdentityProfileDto? profile,
    IamUiFailure? failure,
    bool? isOwner,
    bool clearFailure = false,
    bool clearProfile = false,
  }) {
    return MyAccountState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      failure: clearFailure ? null : (failure ?? this.failure),
      isOwner: isOwner ?? this.isOwner,
    );
  }
}
