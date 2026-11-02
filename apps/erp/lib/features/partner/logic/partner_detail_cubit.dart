import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/partner_error_codes.dart';
import '../data/partner_repository.dart';
import 'partner_detail_state.dart';

final class PartnerDetailCubit extends Cubit<PartnerDetailState> {
  PartnerDetailCubit({required PartnerRepository repository})
    : _repository = repository,
      super(const PartnerDetailInitial());

  final PartnerRepository _repository;

  Future<void> loadDetail(String partnerId) async {
    emit(const PartnerDetailLoading());
    try {
      final result = await _repository.getDetail(partnerId);
      // Contact-only Person (no customer/supplier role) is not a working-list
      // partner — manage via organization detail (EP-01/US-05), not SG-03.
      if (result.roles.isEmpty) {
        emit(const PartnerDetailError(
          'CONTACT_ONLY: manage via organization',
          isNotFound: true,
          isContactOnly: true,
        ));
        return;
      }
      emit(PartnerDetailLoaded(result));
    } catch (e) {
      final code = e is AppException ? e.code : null;
      emit(PartnerDetailError(
        e.toString(),
        isNotFound: code == PartnerErrorCodes.notFound,
        isNoPermission: code == PartnerErrorCodes.noPermission,
      ));
    }
  }
}
