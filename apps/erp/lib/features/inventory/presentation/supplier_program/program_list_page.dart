import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_list_cubit.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_list_state.dart';
import 'package:erp/features/inventory/logic/supplier_program/supplier_program_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/patterns/k6_task_list.dart';
import 'package:erp/features/inventory/presentation/supplier_program/program_filter_sheet.dart';
import 'package:erp/features/inventory/presentation/supplier_program/program_row_below.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

class ProgramListPage extends StatelessWidget {
  final String? initialSupplierId;

  const ProgramListPage({
    super.key,
    this.initialSupplierId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProgramListCubit(
        repository: getIt<SupplierProgramRepository>(),
        initialSupplierId: initialSupplierId,
      )..load(),
      child: const _ProgramListView(),
    );
  }
}

class _ProgramListView extends StatefulWidget {
  const _ProgramListView();

  @override
  State<_ProgramListView> createState() => _ProgramListViewState();
}

class _ProgramListViewState extends State<_ProgramListView> {
  GoRouter? _router;
  String? _lastLocation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (_router != router) {
      _router?.routerDelegate.removeListener(_onRouteChanged);
      _router = router;
      _router?.routerDelegate.addListener(_onRouteChanged);
    }
    _lastLocation = _router?.routerDelegate.currentConfiguration.uri.path;
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final path = _router?.state.uri.path ??
        _router?.routerDelegate.currentConfiguration.uri.path;
    if (path != _lastLocation) {
      final wasChild = _lastLocation != null &&
          _lastLocation!.startsWith('/warehouse/supplier-programs/');
      _lastLocation = path;
      if (wasChild && path == '/warehouse/supplier-programs') {
        context.read<ProgramListCubit>().refresh();
      }
    }
  }

  void _backToHub(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/warehouse');
    }
  }

  Future<void> _openCreate(BuildContext context, ProgramListState state) async {
    final cubit = context.read<ProgramListCubit>();
    final supId = state.supplierId;
    final route = supId != null && supId.isNotEmpty
        ? '/warehouse/supplier-programs/new?supplierId=$supId'
        : '/warehouse/supplier-programs/new';
    await context.push(route);
    if (mounted) {
      await cubit.refresh();
    }
  }

  Future<void> _openDetail(BuildContext context, ProgramRow row) async {
    final cubit = context.read<ProgramListCubit>();
    await context.push('/warehouse/supplier-programs/${row.id}');
    if (mounted) {
      await cubit.refresh();
    }
  }

  Future<void> _pickSupplier(
    BuildContext context,
    ProgramListCubit cubit,
    ProgramListState state,
  ) async {
    final suppliers = state.options?.suppliers ?? const [];
    final picked = await showProgramFilterSheet(
      context: context,
      title: 'Nhà cung cấp',
      items: [
        for (final s in suppliers)
          ProgramFilterItem(id: s.partnerId, label: s.displayName),
      ],
      selectedId: state.supplierId,
    );
    if (picked == null) return;
    cubit.setSupplier(picked.isEmpty ? null : picked);
  }

  Future<void> _pickProduct(
    BuildContext context,
    ProgramListCubit cubit,
    ProgramListState state,
  ) async {
    final products = state.options?.products ?? const [];
    final picked = await showProgramFilterSheet(
      context: context,
      title: 'Sản phẩm',
      items: [
        for (final p in products)
          ProgramFilterItem(
            id: p.productId,
            label: p.name,
            subtitle: '${p.code} · ${p.baseUom}',
          ),
      ],
      selectedId: state.productId,
    );
    if (picked == null) return;
    cubit.setProduct(picked.isEmpty ? null : picked);
  }

  String _supplierChipLabel(ProgramListState state) {
    final id = state.supplierId;
    if (id == null) return 'NCC: Tất cả ▾';
    final match = state.options?.suppliers
        .where((s) => s.partnerId == id)
        .firstOrNull;
    final name = match?.displayName ?? id;
    return 'NCC: $name ▾';
  }

  String _productChipLabel(ProgramListState state) {
    final id = state.productId;
    if (id == null) return 'Sản phẩm: Tất cả ▾';
    final match = state.options?.products
        .where((p) => p.productId == id)
        .firstOrNull;
    final name = match?.name ?? id;
    return 'Sản phẩm: $name ▾';
  }

  List<K7Column<ProgramRow>> _buildColumns(BuildContext context) {
    final colors = context.vColors;
    return [
      K7Column<ProgramRow>(
        label: 'Tên',
        cell: (r) => VText(
          r.name,
          variant: VTextVariant.bodyDefault,
          color: colors.textPrimary,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      K7Column<ProgramRow>(
        label: 'Nhà cung cấp',
        cell: (r) => VText(
          r.supplierName,
          variant: VTextVariant.bodyDefault,
          color: colors.textPrimary,
        ),
      ),
      K7Column<ProgramRow>(
        label: 'Loại',
        cell: (r) => VText(
          programKindShort(r.kind),
          variant: VTextVariant.bodyDefault,
          color: colors.textSecondary,
        ),
      ),
      K7Column<ProgramRow>(
        label: 'Ưu đãi',
        cell: (r) => ProgramRowBelow(r),
      ),
      K7Column<ProgramRow>(
        label: 'Trạng thái',
        cell: (r) => VBadge(
          label: programStatusLabel(r.status),
          tone: programStatusTone(r.status),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ProgramListCubit>();
    final state = cubit.state;
    final isWide = inventoryIsWide(context);

    final showMobileFooter = !isWide &&
        (state.status == ProgramListStatus.ready ||
            state.status == ProgramListStatus.empty);

    return VPageScaffold(
      title: 'Chương trình NCC',
      contentMaxWidth: isWide
          ? VPageScaffold.fullWidth
          : VPageScaffold.defaultContentMaxWidth,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Quay về Kho',
        onPressed: () => _backToHub(context),
      ),
      actions: isWide &&
              (state.status == ProgramListStatus.ready ||
                  state.status == ProgramListStatus.empty)
          ? [
              Padding(
                padding: const EdgeInsets.only(right: VSpacing.space2),
                child: VButton(
                  label: 'Tạo chương trình',
                  variant: VButtonVariant.primary,
                  leading: VIcons.add,
                  onPressed: () => _openCreate(context, state),
                ),
              ),
            ]
          : null,
      bottomBar: showMobileFooter
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space4,
                vertical: VSpacing.space3,
              ),
              child: InventoryFooter(
                actions: [
                  InventoryFooterAction(
                    label: 'Tạo chương trình',
                    primary: true,
                    onPressed: () => _openCreate(context, state),
                  ),
                ],
              ),
            )
          : null,
      body: Builder(
        builder: (context) {
          if (state.status == ProgramListStatus.loading) {
            return const Padding(
              padding: EdgeInsets.all(VSpacing.space4),
              child: InventoryLoading(
                blocks: [
                  InventorySkeletonBlock.search,
                  InventorySkeletonBlock.row,
                  InventorySkeletonBlock.row,
                  InventorySkeletonBlock.row,
                ],
              ),
            );
          }

          if (state.status == ProgramListStatus.loadError) {
            return Center(
              child: InventoryEmpty(
                title: 'Không tải được danh sách',
                description: 'Kiểm tra kết nối rồi thử lại.',
                actionLabel: 'Thử lại',
                onAction: cubit.load,
              ),
            );
          }

          if (state.status == ProgramListStatus.empty) {
            return Center(
              child: InventoryEmpty(
                title: 'Chưa có chương trình nhà cung cấp',
                description:
                    'Khai báo ưu đãi của nhà cung cấp để áp khi nhận hàng.',
                actionLabel: 'Tạo chương trình',
                onAction: () => _openCreate(context, state),
              ),
            );
          }

          final dimensionChips = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                VChip(
                  label: _supplierChipLabel(state),
                  tone: state.supplierId != null
                      ? VComponentTone.primary
                      : VComponentTone.neutral,
                  onTap: () => _pickSupplier(context, cubit, state),
                ),
                const SizedBox(width: VSpacing.space2),
                VChip(
                  label: _productChipLabel(state),
                  tone: state.productId != null
                      ? VComponentTone.primary
                      : VComponentTone.neutral,
                  onTap: () => _pickProduct(context, cubit, state),
                ),
              ],
            ),
          );

          final statusChips = K7FilterChips(
            items: [
              for (final s in ProgramStatus.values)
                K7Filter(
                  key: s.name,
                  label: programStatusLabel(s),
                  count: state.count(s),
                ),
            ],
            selected: state.statusFilter.name,
            onSelected: (key) {
              final next = ProgramStatus.values.firstWhere(
                (s) => s.name == key,
                orElse: () => ProgramStatus.active,
              );
              cubit.setStatus(next);
            },
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 1160 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isWide) ...[
                      Row(
                        children: [
                          Expanded(
                            child: VSearchBar(
                              hintText: 'Tìm tên chương trình',
                              onChanged: cubit.setQuery,
                              onClear: () => cubit.setQuery(''),
                            ),
                          ),
                          const SizedBox(width: VSpacing.space3),
                          dimensionChips,
                        ],
                      ),
                      const SizedBox(height: VSpacing.space3),
                      statusChips,
                      const SizedBox(height: VSpacing.space3),
                      K6TaskList<ProgramRow>(
                        columns: _buildColumns(context),
                        rows: state.visible,
                        total: state.all.length,
                        title: (r) => r.name,
                        subtitle: (r) =>
                            '${r.supplierName} · ${programKindShort(r.kind)}',
                        below: (r) => ProgramRowBelow(r),
                        status: (r) => K6Status(
                          label: programStatusLabel(r.status),
                          tone: programStatusTone(r.status),
                        ),
                        onOpen: (r) => _openDetail(context, r),
                        empty: InventoryEmpty(
                          title: 'Chưa có chương trình nhà cung cấp',
                          description:
                              'Khai báo ưu đãi của nhà cung cấp để áp khi nhận hàng.',
                          actionLabel: 'Tạo chương trình',
                          onAction: () => _openCreate(context, state),
                        ),
                        filterEmpty: InventoryEmpty(
                          title: 'Không có chương trình phù hợp',
                          description: 'Thử bộ lọc khác.',
                          actionLabel: 'Xóa bộ lọc',
                          onAction: cubit.clearFilters,
                        ),
                      ),
                    ] else ...[
                      VSearchBar(
                        hintText: 'Tìm tên chương trình',
                        onChanged: cubit.setQuery,
                        onClear: () => cubit.setQuery(''),
                      ),
                      const SizedBox(height: VSpacing.space3),
                      dimensionChips,
                      const SizedBox(height: VSpacing.space3),
                      K6TaskList<ProgramRow>(
                        filters: statusChips,
                        columns: _buildColumns(context),
                        rows: state.visible,
                        total: state.all.length,
                        title: (r) => r.name,
                        subtitle: (r) =>
                            '${r.supplierName} · ${programKindShort(r.kind)}',
                        below: (r) => ProgramRowBelow(r),
                        status: (r) => K6Status(
                          label: programStatusLabel(r.status),
                          tone: programStatusTone(r.status),
                        ),
                        onOpen: (r) => _openDetail(context, r),
                        empty: InventoryEmpty(
                          title: 'Chưa có chương trình nhà cung cấp',
                          description:
                              'Khai báo ưu đãi của nhà cung cấp để áp khi nhận hàng.',
                          actionLabel: 'Tạo chương trình',
                          onAction: () => _openCreate(context, state),
                        ),
                        filterEmpty: InventoryEmpty(
                          title: 'Không có chương trình phù hợp',
                          description: 'Thử bộ lọc khác.',
                          actionLabel: 'Xóa bộ lọc',
                          onAction: cubit.clearFilters,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
