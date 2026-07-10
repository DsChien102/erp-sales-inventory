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

class PartnerListPage extends StatefulWidget {
  const PartnerListPage({super.key});

  @override
  State<PartnerListPage> createState() => _PartnerListPageState();
}

class _PartnerListPageState extends State<PartnerListPage> {
  final ScrollController _scrollController = ScrollController();
  late final PartnerListCubit _cubit;

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cubit.fetchPartners();
    }
  }

  bool get _canCreate =>
      GetIt.instance<IamSession>().hasPermission(PartnerPermissions.create);

  Future<void> _openCreateFlow() async {
    final partnerType = await showPartnerCreateActionSheet(context);
    if (!mounted || partnerType == null) return;

    final createdPartnerId = await context.push<String>(
      '/partner/new',
      extra: partnerType,
    );
    if (!mounted) return;
    if (createdPartnerId != null) {
      await _cubit.fetchPartners(isRefresh: true);
      _showCreatedHandoffSnackBar(createdPartnerId);
    } else {
      await _cubit.fetchPartners(isRefresh: true);
    }
  }

  void _showCreatedHandoffSnackBar(String partnerId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã tạo KH & NCC. Chi tiết hồ sơ sẽ có ở bản cập nhật tiếp theo.',
          style: VTypography.bodyDefault.copyWith(color: VColors.neutral0),
        ),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: VColors.neutral0,
          onPressed: () {},
        ),
        backgroundColor: VColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.card)),
        margin: const EdgeInsets.all(VSpacing.space4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final canView = GetIt.instance<IamSession>().hasPermission(PartnerPermissions.view);

    if (!canView) {
      return Scaffold(
        key: const Key('wgt_e01_u02_fr01_02'),
        backgroundColor: colors.background,
        appBar: const VAppBar(title: 'KH & NCC', showBackButton: false),
        body: const Center(
          child: Text('Bạn chưa có quyền xem danh sách KH & NCC.'),
        ),
      );
    }

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        key: const Key('wgt_e01_u02_fr01_02'),
        backgroundColor: colors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: BlocBuilder<PartnerListCubit, PartnerListState>(
            builder: (context, state) {
              final total = switch (state) {
                PartnerListLoaded(:final total) => total,
                _ => null,
              };
              return VAppBar(
                title: 'KH & NCC',
                subtitle: total != null ? '$total hồ sơ' : null,
                showBackButton: false,
              );
            },
          ),
        ),
        body: Column(
          children: [
            PartnerListSearchBar(onSearch: _cubit.searchByKeyword),
            Expanded(
              child: BlocBuilder<PartnerListCubit, PartnerListState>(
                builder: (context, state) {
                  if (state is PartnerListInitial ||
                      (state is PartnerListLoading && state.isFirstLoad)) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is PartnerListError) {
                    return Center(child: Text('Lỗi: ${state.message}'));
                  }

                  final items = switch (state) {
                    PartnerListLoaded(:final items) => items,
                    PartnerListLoading(:final items) => items,
                    _ => <PartnerListItemDto>[],
                  };

                  if (items.isEmpty && state is! PartnerListLoading) {
                    return Center(
                      child: VEmptyState(
                        iconData: Icons.people_outline_rounded,
                        title: 'Chưa có KH & NCC',
                        description: 'Bắt đầu bằng cách thêm hồ sơ cá nhân hoặc tổ chức mới.',
                        actionLabel: _canCreate ? 'Thêm KH & NCC' : null,
                        actionLeadingIcon: _canCreate ? const Icon(Icons.add, size: 18) : null,
                        onActionPressed: _canCreate ? _openCreateFlow : null,
                      ),
                    );
                  }

                  final hasReachedMax = state is PartnerListLoaded && state.hasReachedMax;

                  return RefreshIndicator(
                    onRefresh: () => _cubit.fetchPartners(isRefresh: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length + (hasReachedMax ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (index >= items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: VSpacing.space4),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = items[index];
                        return PartnerListItemTile(
                          item: item,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Hồ sơ ${item.displayName} — chi tiết sẽ có ở bản cập nhật tiếp theo.',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _canCreate
            ? VFloatingActionButton(
                key: const Key('btn_create_partner'),
                iconData: Icons.add,
                onTap: _openCreateFlow,
                backgroundColor: colors.success,
              )
            : null,
      ),
    );
  }
}
