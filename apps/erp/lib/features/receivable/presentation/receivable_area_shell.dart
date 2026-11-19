import 'package:erp/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../data/receivable_repository.dart';
import '../logic/receivable_list_cubit.dart';
import 'pages/receivable_list_page.dart';

/// Shell khu công nợ phải thu: một [ReceivableListCubit] cho CN-01 và CN-02,
/// chia 2 cột trên web rộng (danh sách trái, công nợ khách phải). Chép khuôn `PartnerAreaShell`.
///
/// Quyền `receivable.view` được kiểm ở builder của `ShellRoute` trong `receivable_routes.dart`.
class ReceivableAreaShell extends StatelessWidget {
  const ReceivableAreaShell({
    super.key,
    required this.child,
    this.selectedId,
    this.repository,
    this.cubit,
  });

  final Widget child;
  final String? selectedId;
  final ReceivableRepository? repository;

  /// Chỉ cho test: dùng cubit có sẵn, shell không tạo và không tải.
  final ReceivableListCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(value: cubit!, child: _layout(cubit!));
    }
    return BlocProvider(
      create: (_) => ReceivableListCubit(repository: repository ?? getIt<ReceivableRepository>())..load(),
      child: Builder(builder: (context) => _layout(context.read<ReceivableListCubit>())),
    );
  }

  Widget _layout(ReceivableListCubit listCubit) => VListDetailLayout(
    listWidth: 380,
    list: ReceivableListPage(cubit: listCubit, selectedId: selectedId),
    detail: child,
  );
}
