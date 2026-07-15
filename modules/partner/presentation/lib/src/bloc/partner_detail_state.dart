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
  const PartnerDetailLoaded(this.dto, {this.selectedTabIndex = 0});

  final PartnerDetailDto dto;
  final int selectedTabIndex;

  // Keep detail getter for backwards compatibility if needed, or maps.
  PartnerDetailDto get detail => dto;

  @override
  List<Object?> get props => [dto, selectedTabIndex];
}

final class PartnerDetailError extends PartnerDetailState {
  const PartnerDetailError(
    this.message, {
    this.isNotFound = false,
    this.isNoPermission = false,
    this.isContactOnly = false,
  });

  final String message;
  final bool isNotFound;
  final bool isNoPermission;

  /// Person không có role KH/NCC — chỉ quản lý qua hồ sơ tổ chức (S5).
  final bool isContactOnly;

  @override
  List<Object?> get props => [message, isNotFound, isNoPermission, isContactOnly];
}
