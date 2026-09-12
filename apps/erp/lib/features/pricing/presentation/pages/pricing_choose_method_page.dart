import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_application/application.dart';

/// S4 — Chọn phương thức thêm giá riêng (SG-03 D-01).
///
/// Quyền hiển thị lấy từ `SearchCustomerPriceRulesQuery.availableActions`
/// (create_manual / import) — không cache từ màn list.
class PricingChooseMethodPage extends StatefulWidget {
  const PricingChooseMethodPage({
    super.key,
    this.canCreate,
    this.canImport,
  });

  /// Chỉ dùng trong widget test — bỏ qua gọi backend khi cả hai được set.
  final bool? canCreate;

  /// Chỉ dùng trong widget test — bỏ qua gọi backend khi cả hai được set.
  final bool? canImport;

  @override
  State<PricingChooseMethodPage> createState() => _PricingChooseMethodPageState();
}

class _PricingChooseMethodPageState extends State<PricingChooseMethodPage> {
  bool _isLoading = true;
  bool _canCreate = false;
  bool _canImport = false;
  String? _errorMessage;

  bool get _usesExplicitCapabilities => widget.canCreate != null && widget.canImport != null;

  @override
  void initState() {
    super.initState();
    if (_usesExplicitCapabilities) {
      _canCreate = widget.canCreate!;
      _canImport = widget.canImport!;
      _isLoading = false;
    } else {
      _loadCapabilities();
    }
  }

  Future<void> _loadCapabilities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final tenantId = await GetIt.instance<IExecutionContext>().requireTenantId();
      final result = await GetIt.instance<IPricingModule>().executeQueryAsync(
        SearchCustomerPriceRulesQuery(
          tenantId: tenantId,
          businessDate: VDateTime.currentBusinessDate(),
          limit: 1,
        ),
      );
      if (!mounted) return;
      setState(() {
        _canCreate = result.availableActions.contains(
          PricingAvailableActions.createManual,
        );
        _canImport = result.availableActions.contains(
          PricingAvailableActions.import,
        );
        _isLoading = false;
      });
    } on PricingBlockedException catch (e) {
      if (!mounted) return;
      if (e.code == PricingBlockedCodes.noPermission) {
        setState(() {
          _canCreate = false;
          _canImport = false;
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }
      setState(() {
        _canCreate = false;
        _canImport = false;
        _isLoading = false;
        _errorMessage = _messageForBlocked(e);
      });
    } on ApplicationException catch (e) {
      if (!mounted) return;
      setState(() {
        _canCreate = false;
        _canImport = false;
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _canCreate = false;
        _canImport = false;
        _isLoading = false;
        _errorMessage = 'Không thể tải quyền thao tác. Vui lòng thử lại.';
      });
    }
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/pricing');
    }
  }

  Future<void> _openManualCreate(BuildContext context) async {
    final rule = await context.push<CustomerPriceRuleDetailDto>(
      '/pricing/new',
    );
    if (!context.mounted || rule == null) return;

    if (context.canPop()) {
      context.pop(rule.id);
    } else {
      context.go('/pricing/${rule.id}');
    }
  }

  String _messageForBlocked(PricingBlockedException e) => switch (e.code) {
    PricingBlockedCodes.validationError => e.message ?? 'Dữ liệu không hợp lệ.',
    PricingBlockedCodes.systemError => 'Không thể tải quyền thao tác. Vui lòng thử lại.',
    _ => e.message ?? 'Không thể tải quyền thao tác. Vui lòng thử lại.',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final leading = IconButton(
      icon: VIcon(icon: VIcons.arrowBack, color: colors.textPrimary),
      onPressed: () => _handleBack(context),
    );

    if (_isLoading) {
      return VPageScaffold(
        title: 'Thêm giá riêng',
        showBackButton: false,
        leading: leading,
        body: const VSkeletonScope(
          child: Padding(
            padding: EdgeInsets.all(VSpacing.space4),
            child: Column(
              children: [
                VSkeleton(width: double.infinity, height: 88),
                VGap.md(),
                VSkeleton(width: double.infinity, height: 88),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return VPageScaffold(
        title: 'Thêm giá riêng',
        showBackButton: false,
        leading: leading,
        body: VEmptyState(
          icon: VIcons.error,
          title: 'Không thể tải dữ liệu',
          description: _errorMessage!,
          actionLabel: 'Thử lại',
          onActionPressed: _loadCapabilities,
        ),
      );
    }

    return VPageScaffold(
      key: const Key('wgt_e02_u02_fr01_01'),
      title: 'Thêm giá riêng',
      showBackButton: false,
      leading: leading,
      body: VPagePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const VGap.md(),
            VText('Chọn cách thêm', variant: VTextVariant.headingH4),
            const VGap.xs(),
            VText(
              'Bạn muốn tạo giá riêng theo cách nào?',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const VGap.md(),
            if (_canCreate)
              _MethodCard(
                icon: VIcons.addCircle,
                title: 'Tạo thủ công',
                description: 'Nhập thông tin giá riêng cho từng khách hàng.',
                onTap: () => _openManualCreate(context),
              ),
            if (_canCreate && _canImport) const VGap.sm(),
            if (_canImport)
              _MethodCard(
                icon: VIcons.download,
                title: 'Nhập từ Excel',
                description: 'Tạo nhiều giá riêng cùng lúc bằng file Excel mẫu.',
                onTap: () => context.push('/pricing/import'),
              ),
            if (!_canCreate && !_canImport) ...[
              const VEmptyState(
                icon: VIcons.shield,
                title: 'Không có quyền',
                description: 'Bạn không có quyền tạo hoặc nhập giá riêng.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final VIcons icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      onTap: onTap,
      child: Row(
        children: [
          VIconBox(
            icon: icon,
            size: 44,
            iconSize: 22,
            tone: VComponentTone.primary,
            borderRadius: VRadius.r12,
          ),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(title, variant: VTextVariant.headingH4),
                const VGap.xs(),
                VText(
                  description,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          VIcon(
            icon: VIcons.chevronRight,
            color: colors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
