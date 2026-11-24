import '../data/models/my_account.dart';
import 'iam_load_status.dart';
import 'iam_ui_failure.dart';

final class MyAccountEditState {
  const MyAccountEditState({
    this.status = IamLoadStatus.initial,
    this.profile,
    this.isSubmitting = false,
    this.failure,
    this.savedProfile,
  });

  final IamLoadStatus status;
  final MyAccount? profile;
  final bool isSubmitting;
  final IamUiFailure? failure;
  final MyAccount? savedProfile;

  MyAccountEditState copyWith({
    IamLoadStatus? status,
    MyAccount? profile,
    bool? isSubmitting,
    IamUiFailure? failure,
    MyAccount? savedProfile,
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
