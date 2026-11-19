import 'package:erp/core/session/session_controller.dart';
import 'package:erp/features/sales/data/sales_draft_repository.dart';
import 'package:erp/features/sales/logic/sales_draft_list_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../support/i_sales_active_store_context.dart';

/// Giữ một [SalesDraftListCubit] dùng chung cho SG-01 (danh sách nháp) và SG-02
/// (compose), nên số đếm nháp ở compose và danh sách ở SG-01 đọc cùng một cache
/// thay vì mỗi màn tự chạy `ListSalesOrderDraftsQuery`.
///
/// Được cài ở `ShellRoute` bao `/sales/drafts` + `/sales/compose`: cache sống
/// khi còn ở trong nhánh sales, rời hẳn nhánh thì hủy.
class SalesDraftListScope extends StatefulWidget {
  const SalesDraftListScope({super.key, required this.child});

  final Widget child;

  @override
  State<SalesDraftListScope> createState() => _SalesDraftListScopeState();
}

class _SalesDraftListScopeState extends State<SalesDraftListScope> {
  late final SalesDraftListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SalesDraftListCubit(
      repository: GetIt.instance<SalesDraftRepository>(),
      session: GetIt.instance<SessionController>(),
      activeStoreContext: _SalesActiveStoreAdapter(
        GetIt.instance<SessionController>(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: widget.child,
    );
  }
}

final class _SalesActiveStoreAdapter implements ISalesActiveStoreContext {
  const _SalesActiveStoreAdapter(this._inner);

  final SessionController _inner;

  @override
  String? get activeStoreId => _inner.activeStoreId;

  @override
  Future<String> requireActiveStoreId() => _inner.requireActiveStoreId();
}
