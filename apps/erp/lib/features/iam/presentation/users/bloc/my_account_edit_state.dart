import 'package:vet45_iam_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/iam_ui_failure.dart';

final class MyAccountEditState {
  const MyAccountEditState({
    this.status = IamLoadStatus.initial,
    this.profile,
    this.isSubmitting = false,
    this.failure,
    this.savedProfile,
  });

  final IamLoadStatus status;
  final MyIdentityProfileDto? profile;
  final bool isSubmitting;
  final IamUiFailure? failure;
  final MyIdentityProfileDto? savedProfile;

  MyAccountEditState copyWith({
    IamLoadStatus? status,
    MyIdentityProfileDto? profile,
    bool? isSubmitting,
    IamUiFailure? failure,
    MyIdentityProfileDto? savedProfile,
    bool clearFailure = false,
    bool clearSaved = false,
  }) {
    return MyAccountEditState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearFailure ? null : (failure ?? this.failure),
      savedProfile: clearSaved ? null : (savedProfile ?? this.savedProfile),
    );
  }
}
