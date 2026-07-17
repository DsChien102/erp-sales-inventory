import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../widgets/partner_list_body.dart';
import '../widgets/partner_list_header_row.dart';

class PartnerListPage extends StatefulWidget {
  const PartnerListPage({super.key});

  @override
  State<PartnerListPage> createState() => _PartnerListPageState();
}

class _PartnerListPageState extends State<PartnerListPage> {
  final ScrollController _scrollController = ScrollController();
  late final PartnerListCubit _cubit;
  int? _lastTotal;

  @override
  void initState() {
    super.initState();
    _cubit = PartnerListCubit(
      partnerModule: GetIt.instance<IPartnerModule>(),
      executionContext: GetIt.instance<IExecutionContext>(),
    )..fetchPartners();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _cubit.fetchPartners();
    }
  }

  bool get _canCreate => GetIt.instance<IamSession>().hasPermission(PartnerPermissions.create);

  Future<void> _openCreateFlow() async {
    final partnerType = await showPartnerCreateActionSheet(context);
    if (!mounted || partnerType == null) return;

    final createdPartnerId = await context.push<String>(
      '/partner/new',
      extra: partnerType,
    );
    if (!mounted) return;

    // Always refresh when returning from create (success or cancel).
    await _cubit.fetchPartners(isRefresh: true);
    if (!mounted) return;

    if (createdPartnerId != null) {
      // Detail page shows VToast via ?created=1; refresh again after handoff.
      await context.push('/partner/$createdPartnerId?created=1');
      if (mounted) {
        await _cubit.fetchPartners(isRefresh: true);
      }
    }
  }

  Future<void> _openPartnerDetail(String partnerId) async {
    final deleted = await context.push<bool>('/partner/$partnerId');
    if (!mounted) return;
    // Refresh after detail (edit / status / soft-delete / transform).
    await _cubit.fetchPartners(isRefresh: true);
    if (!mounted) return;
    if (deleted == true) {
      showPartnerSoftDeleteSuccessToast(context);
    }
  }

  Future<void> _openFilterSheet(PartnerListState state) async {
    final result = await PartnerFilterBottomSheet.show(
      context,
      role: state.roleFilter,
      partnerType: state.partnerType,
      status: state.status,
      updatedTimeFilter: state.updatedTimeFilter,
    );
    if (result != null) {
      _cubit.applyFilters(
        roleFilter: result['role'] as PartnerRoleFilter?,
        partnerType: result['partnerType'] as PartnerType?,
        status: result['status'] as PartnerStatus?,
        updatedTimeFilter: result['updatedTimeFilter'] as PartnerUpdatedTimeFilter?,
        clearRole: result['role'] == null,
        clearType: result['partnerType'] == null,
        clearStatus: result['status'] == null,
        clearUpdatedTime: result['updatedTimeFilter'] == null,
      );
    }
  }

  Future<void> _openSortSheet(PartnerListState state) async {
    final result = await PartnerSortBottomSheet.show(
      context,
      initialSort: state.sortOption,
    );
    if (result != null && result != state.sortOption) {
      _cubit.applyFilters(sortOption: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final canView = GetIt.instance<IamSession>().hasPermission(PartnerPermissions.view);

    if (!canView) {
      return VPageScaffold(
        key: const Key('wgt_e01_u02_fr01_02'),
        title: 'KH & NCC',
        showBackButton: false,
        body: const Center(
          child: VEmptyState(
            icon: VIcons.lock,
            title: 'Bạn không có quyền xem\nKH & NCC',
            description: 'Liên hệ quản trị viên để được cấp quyền.',
          ),
        ),
      );
    }

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<PartnerListCubit, PartnerListState>(
        builder: (context, state) {
          if (state is PartnerListLoaded) {
            _lastTotal = state.total;
          }
          final total = state is PartnerListLoaded ? state.total : (_lastTotal ?? 0);

          return VPageScaffold(
            key: const Key('wgt_e01_u02_fr01_02'),
            title: 'KH & NCC',
            subtitle: '$total đối tác',
            centerTitle: false,
            showBackButton: false,
            resizeToAvoidBottomInset: false,
            floatingActionButton: _canCreate
                ? VFloatingActionButton(
                    key: const Key('btn_create_partner'),
                    icon: VIcons.add,
                    tone: VComponentTone.success,
                    backgroundColor: colors.success,
                    semanticLabel: 'Thêm KH & NCC',
                    onTap: _openCreateFlow,
                  )
                : null,
            body: Column(
              children: [
                const VGap.sm(),
                BlocBuilder<PartnerListCubit, PartnerListState>(
                  builder: (context, state) {
                    final filterCount =
                        (state.partnerType != null ? 1 : 0) +
                        (state.roleFilter != null ? 1 : 0) +
                        (state.status != null ? 1 : 0);
                    final totalFilterCount =
                        filterCount + (state.updatedTimeFilter != null ? 1 : 0);
                    return PartnerListSearchBar(
                      onSearch: _cubit.searchByKeyword,
                      onFilterTap: () => _openFilterSheet(state),
                      activeFilterCount: totalFilterCount,
                    );
                  },
                ),
                const VGap.sm(),
                BlocBuilder<PartnerListCubit, PartnerListState>(
                  builder: (context, state) {
                    return PartnerListQuickFilters(
                      selectedRole: state.roleFilter,
                      onRoleSelected: (role) {
                        if (role == null) {
                          _cubit.applyFilters(clearRole: true);
                        } else {
                          _cubit.applyFilters(roleFilter: role);
                        }
                      },
                    );
                  },
                ),
                const VGap.sm(),
                PartnerListHeaderRow(onSortTap: _openSortSheet),
                const VGap.sm(),
                Expanded(
                  child: PartnerListBody(
                    scrollController: _scrollController,
                    canCreate: _canCreate,
                    onRefresh: () => _cubit.fetchPartners(isRefresh: true),
                    onRetry: () => _cubit.fetchPartners(isRefresh: true),
                    onClearQuery: () => _cubit.searchByKeyword(''),
                    onCreate: _openCreateFlow,
                    onTapPartner: _openPartnerDetail,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
