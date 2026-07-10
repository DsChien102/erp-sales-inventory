import 'package:equatable/equatable.dart';
import 'package:vet45_partner_application/application.dart';

sealed class PartnerDetailState extends Equatable {
  const PartnerDetailState();

  @override
  List<Object?> get props => [];
}

final class PartnerDetailInitial extends PartnerDetailState {
  const PartnerDetailInitial();
}

final class PartnerDetailLoading extends PartnerDetailState {
  const PartnerDetailLoading();
}

final class PartnerDetailLoaded extends PartnerDetailState {
  const PartnerDetailLoaded({
    required this.detail,
    this.selectedTabIndex = 0,
  });

  final PartnerDetailDto detail;
  final int selectedTabIndex;

  PartnerDetailLoaded copyWith({
    PartnerDetailDto? detail,
    int? selectedTabIndex,
  }) {
    return PartnerDetailLoaded(
      detail: detail ?? this.detail,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }

  @override
  List<Object?> get props => [detail, selectedTabIndex];
}

final class PartnerDetailError extends PartnerDetailState {
  const PartnerDetailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
