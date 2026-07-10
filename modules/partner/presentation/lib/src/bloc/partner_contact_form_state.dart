import 'package:equatable/equatable.dart';
import 'package:vet45_partner_application/application.dart';

enum PartnerContactFormStatus {
  initial,
  loadingPersonDetail,
  submitting,
  success,
  duplicate,
  error,
}

final class PartnerContactFormState extends Equatable {
  const PartnerContactFormState({
    this.status = PartnerContactFormStatus.initial,
    this.errorMessage,
    this.personDetail,
    this.duplicateMatches = const [],
    this.duplicateLevel,
  });

  final PartnerContactFormStatus status;
  final String? errorMessage;
  final PartnerDetailDto? personDetail;
  final List<PartnerDuplicateMatchDto> duplicateMatches;
  final PartnerDuplicateMatchLevel? duplicateLevel;

  bool get isLoading =>
      status == PartnerContactFormStatus.loadingPersonDetail ||
      status == PartnerContactFormStatus.submitting;

  PartnerContactFormState copyWith({
    PartnerContactFormStatus? status,
    String? errorMessage,
    PartnerDetailDto? personDetail,
    List<PartnerDuplicateMatchDto>? duplicateMatches,
    PartnerDuplicateMatchLevel? duplicateLevel,
    bool clearDuplicate = false,
  }) {
    return PartnerContactFormState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      personDetail: personDetail ?? this.personDetail,
      duplicateMatches: clearDuplicate ? const [] : (duplicateMatches ?? this.duplicateMatches),
      duplicateLevel: clearDuplicate ? null : (duplicateLevel ?? this.duplicateLevel),
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        personDetail,
        duplicateMatches,
        duplicateLevel,
      ];
}
