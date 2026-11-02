import 'package:erp/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../data/partner_repository.dart';
import '../logic/partner_list_cubit.dart';
import 'pages/partner_list_page.dart';

/// Shell khu KH & NCC: giữ một [PartnerListCubit] cho cả danh sách và hồ sơ,
/// chia 2 cột trên web rộng (danh sách trái, hồ sơ phải).
///
/// Quyền `partner.view` được kiểm ở builder của `ShellRoute` trong `app_router.dart`;
/// shell này chỉ dựng khi đã có quyền.
class PartnerAreaShell extends StatelessWidget {
  const PartnerAreaShell({
    super.key,
    required this.child,
    this.selectedId,
    this.repository,
    this.cubit,
  });

  final Widget child;
  final String? selectedId;
  final PartnerRepository? repository;

  /// Chỉ cho test: dùng cubit có sẵn, shell không tạo và không tải.
  final PartnerListCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: Builder(builder: (context) => _buildLayout(cubit!)),
      );
    }
    return BlocProvider(
      create: (_) => PartnerListCubit(
        repository: repository ?? getIt<PartnerRepository>(),
      )..fetchPartners(),
      child: Builder(
        builder: (context) => _buildLayout(context.read<PartnerListCubit>()),
      ),
    );
  }

  Widget _buildLayout(PartnerListCubit listCubit) {
    return VListDetailLayout(
      list: PartnerListPage(cubit: listCubit, selectedId: selectedId),
      detail: child,
    );
  }
}
