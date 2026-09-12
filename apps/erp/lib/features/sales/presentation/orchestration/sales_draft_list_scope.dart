import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_iam_application/application.dart' as iam;
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../bloc/sales_order_draft/sales_draft_list_cubit.dart';
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
      salesModule: GetIt.instance<ISalesModule>(),
      executionContext: GetIt.instance<IExecutionContext>(),
      activeStoreContext: _SalesActiveStoreAdapter(
        GetIt.instance<iam.IActiveStoreContext>(),
      ),
      actorNameResolver: _resolveActorName,
    )..load();
  }

  static Future<String?> _resolveActorName(String actorId) async {
    try {
      final executionContext = GetIt.instance<IExecutionContext>();
      final myUserId = await executionContext.requireUserId();
      if (actorId == myUserId) {
        final iamModule = GetIt.instance<iam.IIamModule>();
        final profile = await iamModule.executeQueryAsync(
          iam.GetMyIdentityProfileQuery(),
        );
        final fullName = profile.fullName.trim();
        if (fullName.isNotEmpty) return fullName;
        final email = profile.email.trim();
        if (email.isNotEmpty) return email;
      }
      return null;
    } catch (_) {
      return null;
    }
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

  final iam.IActiveStoreContext _inner;

  @override
  String? get activeStoreId => _inner.activeStoreId;

  @override
  Future<String> requireActiveStoreId() => _inner.requireActiveStoreId();
}
