import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/shared/sales_sellable_product_vm.dart';
import '../support/sales_external_lookups.dart';
import 'package:erp/core/formatting/money_formatter.dart';
/// Search SG-02 (Hình 2): gõ → menu tối đa 4 vcard (đơn vị cơ sở), nổi trên list.
///
/// Dùng [MenuAnchor] (cùng pattern [VCombobox]) để scroll trong panel không làm
/// mất focus và đóng overlay giữa chừng.
class SalesComposeProductSearchBar extends StatefulWidget {
  const SalesComposeProductSearchBar({
    super.key,
    required this.onSelectProduct,
    required this.onScanTap,
    required this.searchProducts,
    required this.resolveBarcode,
  });

  final ValueChanged<SalesSellableProductVm> onSelectProduct;
  final VoidCallback onScanTap;
  final SalesProductSearchFn searchProducts;
  final SalesProductBarcodeResolveFn resolveBarcode;

  @override
  State<SalesComposeProductSearchBar> createState() => _SalesComposeProductSearchBarState();
}

/// Menu của search bar chỉ có đúng một trong các trạng thái này.
enum _SearchPhase { hidden, loading, results, empty, failed }

class _SalesComposeProductSearchBarState extends State<SalesComposeProductSearchBar> {
  static const double _menuMaxHeight = 350;
  static const List<BoxShadow> _menuBoxShadow = VOverlayMenuShell.menuShadow;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode(debugLabel: 'SalesComposeProductSearch');
  final MenuController _menuController = MenuController();
  Timer? _debounce;
  List<SalesSellableProductVm> _suggestions = const [];
  _SearchPhase _phase = _SearchPhase.hidden;
  String? _failureMessage;

  /// Nguồn vừa fail, để nút Thử lại chạy lại đúng nhánh (gõ hoặc quét barcode).
  Future<void> Function()? _retry;

  /// Đã từng hiển thị kết quả/rỗng/lỗi — dùng phân biệt loading lần đầu vs refresh.
  bool _hasResolvedSearch = false;

  /// Tăng khi hủy debounce / unfocus / đóng menu — bỏ kết quả inflight cũ.
  int _searchGeneration = 0;

  /// Submit barcode giữ session dù TextField mất focus tạm thời.
  bool _holdSessionForSubmit = false;

  bool _syncingFocusAndMenu = false;

  /// Khi true, [MenuController.close] không unfocus ô tìm kiếm (vd. đang loading).
  bool _keepFocusOnMenuClose = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchGeneration++;
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_syncingFocusAndMenu) return;

    if (_focusNode.hasFocus) {
      // Focus luôn mở tìm kiếm: rỗng thì hiện danh sách gợi ý mặc định.
      _scheduleSearch(_controller.text.trim());
      if (_shouldShowMenu) {
        _openMenu();
      }
    } else if (!_menuController.isOpen && !_holdSessionForSubmit) {
      // Tap ngoài: hủy debounce; nếu đang fetch (menu chưa mở) thì bỏ inflight
      // để future xong không mở Menu pick SP.
      _debounce?.cancel();
      _debounce = null;
      if (_phase == _SearchPhase.loading) {
        _invalidateInFlightSearch(resetLoadingUi: true);
      }
    }

    if (mounted) setState(() {});
  }

  /// Hủy debounce và đánh dấu mọi search đang chờ là stale.
  void _invalidateInFlightSearch({required bool resetLoadingUi}) {
    _debounce?.cancel();
    _debounce = null;
    _searchGeneration++;
    if (resetLoadingUi && _phase == _SearchPhase.loading) {
      _resetPhase();
    }
  }

  /// Bỏ kết quả stale (generation / query đổi). Không phụ thuộc focus —
  /// unfocus đã invalidate qua [_invalidateInFlightSearch] khi cần.
  bool _shouldApplySearchResult(int generation, String query) {
    if (!mounted || generation != _searchGeneration) return false;
    if (_controller.text.trim() != query) return false;
    return true;
  }

  void _retainSearchFocus() {
    if (_focusNode.hasFocus) return;
    _syncingFocusAndMenu = true;
    _focusNode.requestFocus();
    _syncingFocusAndMenu = false;
  }

  void _handleMenuOpen() {
    if (!_focusNode.hasFocus) {
      _syncingFocusAndMenu = true;
      _focusNode.requestFocus();
      _syncingFocusAndMenu = false;
    }
  }

  void _handleMenuClose() {
    final keepFocus = _keepFocusOnMenuClose;
    _keepFocusOnMenuClose = false;

    if (keepFocus) {
      if (mounted) setState(() {});
      return;
    }

    // Tap outside — hủy inflight + xóa kết quả khi ô tìm không còn focus.
    if (!_focusNode.hasFocus) {
      _invalidateInFlightSearch(resetLoadingUi: false);
      _resetPhase();
    }

    if (mounted) setState(() {});
  }

  void _openMenu({bool requestFocus = false}) {
    if (!_shouldShowMenu) return;
    if (!_menuController.isOpen) {
      _menuController.open();
    }
    if (requestFocus && !_focusNode.hasFocus) {
      _syncingFocusAndMenu = true;
      _focusNode.requestFocus();
      _syncingFocusAndMenu = false;
    }
    if (mounted) setState(() {});
  }

  void _closeMenu({required bool keepFocus}) {
    if (!_menuController.isOpen) return;
    _keepFocusOnMenuClose = keepFocus;
    _menuController.close();
  }

  bool get _shouldShowMenu => switch (_phase) {
    _SearchPhase.hidden => false,
    // Loading lần đầu: chỉ spinner suffix; refresh giữ menu + kết quả cũ
    // (không phụ thuộc focus — tránh blip focus làm trống menuChildren → đóng menu).
    _SearchPhase.loading => _hasResolvedSearch,
    _SearchPhase.results || _SearchPhase.empty || _SearchPhase.failed => true,
  };

  void _syncMenu() {
    if (_shouldShowMenu) {
      _openMenu();
      return;
    }
    _closeMenu(keepFocus: _focusNode.hasFocus);
  }

  void _resetPhase() {
    _phase = _SearchPhase.hidden;
    _suggestions = const [];
    _failureMessage = null;
    _retry = null;
    _hasResolvedSearch = false;
  }

  void _hideSuggestions() {
    setState(_resetPhase);
    _syncMenu();
  }

  /// Vào phase loading: giữ danh sách cũ (nếu có) và **không** đóng menu.
  void _enterLoading() {
    setState(() {
      if (_phase == _SearchPhase.empty || _phase == _SearchPhase.failed) {
        _suggestions = const [];
      }
      _phase = _SearchPhase.loading;
      _failureMessage = null;
      _retry = null;
    });
    _syncMenu();
  }

  void _markSearchResolved() => _hasResolvedSearch = true;

  void _showResults(List<SalesSellableProductVm> results) {
    setState(() {
      _suggestions = results;
      _phase = _SearchPhase.results;
      _failureMessage = null;
      _retry = null;
      _markSearchResolved();
    });
    _syncMenu();
  }

  void _showEmpty() {
    setState(() {
      _suggestions = const [];
      _phase = _SearchPhase.empty;
      _failureMessage = null;
      _retry = null;
      _markSearchResolved();
    });
    _syncMenu();
  }

  void _showFailure(Object error, Future<void> Function() retry) {
    final message = error.toString().trim();
    setState(() {
      _suggestions = const [];
      _phase = _SearchPhase.failed;
      _failureMessage = message.isEmpty ? null : message;
      _retry = retry;
      _markSearchResolved();
    });
    _syncMenu();
  }

  void _onQueryChanged(String value) => _scheduleSearch(value.trim());

  /// Một debounce duy nhất cho cả focus và gõ, nên focus-rồi-gõ ngay chỉ tốn
  /// một request.
  void _scheduleSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      // Unfocus trước khi timer chạy → không bắt đầu fetch / không mở menu.
      if (!_focusNode.hasFocus) return;
      unawaited(_runSearch(query));
    });
  }

  Future<void> _runSearch(String query) async {
    final generation = ++_searchGeneration;
    _enterLoading();

    List<SalesSellableProductVm> found;
    try {
      found = await widget.searchProducts(query, limit: 4);
    } catch (error) {
      if (!_shouldApplySearchResult(generation, query)) return;
      _showFailure(error, () => _runSearch(query));
      return;
    }

    if (!_shouldApplySearchResult(generation, query)) return;

    final results = found.take(4).toList(growable: false);
    if (results.isEmpty) {
      _showEmpty();
      return;
    }
    _showResults(results);
  }

  Future<void> _onSubmitted(String value) async {
    _debounce?.cancel();
    final barcode = value.trim();
    if (barcode.isEmpty) return;
    await _runBarcode(barcode);
  }

  Future<void> _runBarcode(String barcode) async {
    final generation = ++_searchGeneration;
    _holdSessionForSubmit = true;
    _enterLoading();

    try {
      List<SalesSellableProductVm> matches;
      try {
        matches = await widget.resolveBarcode(barcode);
      } catch (error) {
        if (!_shouldApplySearchResult(generation, barcode)) return;
        _showFailure(error, () => _runBarcode(barcode));
        return;
      }

      if (!_shouldApplySearchResult(generation, barcode)) return;
      if (matches.length == 1) {
        _pick(matches.single);
        return;
      }
      if (matches.isEmpty) {
        _showEmpty();
        return;
      }
      _showResults(matches.take(4).toList(growable: false));
    } finally {
      _holdSessionForSubmit = false;
    }
  }

  void _clear() {
    _debounce?.cancel();
    _searchGeneration++;
    _controller.value = TextEditingValue.empty;
    if (_focusNode.hasFocus) {
      // Vẫn đang trong ô tìm kiếm → quay về danh sách gợi ý mặc định.
      _scheduleSearch('');
      return;
    }
    _hideSuggestions();
  }

  void _pick(SalesSellableProductVm product) {
    widget.onSelectProduct(product);
    _debounce?.cancel();
    _searchGeneration++;
    _controller.value = TextEditingValue.empty;
    _hideSuggestions();
    _syncingFocusAndMenu = true;
    _focusNode.unfocus();
    _syncingFocusAndMenu = false;
  }

  Widget _buildMenuPanel(BuildContext context) {
    return switch (_phase) {
      _SearchPhase.loading => _panelShell(
        context,
        key: const Key('wgt_compose_product_loading'),
        child: _buildLoadingPanel(context),
      ),
      _SearchPhase.results when _suggestions.isNotEmpty => _panelShell(
        context,
        key: const Key('wgt_compose_product_suggestions'),
        child: _buildScrollableResults(context),
      ),
      _SearchPhase.empty => _panelShell(
        context,
        key: const Key('wgt_compose_product_empty'),
        child: const VPagePadding(
          vertical: VSpacing.space10,
          child: _SearchEmptyState(),
        ),
      ),
      _SearchPhase.failed => _panelShell(
        context,
        key: const Key('wgt_compose_product_error'),
        child: VPagePadding(
          vertical: VSpacing.space10,
          child: _SearchErrorState(failureMessage: _failureMessage, retry: _retry),
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  /// Trong lúc refresh: giữ kết quả cũ; spinner chỉ ở suffix ô tìm.
  Widget _buildLoadingPanel(BuildContext context) {
    return _buildScrollableResults(context);
  }

  double get _menuListViewportHeight {
    const estimatedRowHeight = 108.0;
    final maxViewport = _menuMaxHeight;
    final contentHeight = _suggestions.length * estimatedRowHeight;
    return math.min(contentHeight, maxViewport);
  }

  Widget _buildScrollableResults(BuildContext context) {
    final viewportHeight = _menuListViewportHeight;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _retainSearchFocus(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) => true,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.stylus,
              PointerDeviceKind.trackpad,
            },
          ),
          child: SizedBox(
            height: viewportHeight,
            child: ListView.separated(
              primary: false,
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: _suggestions.length,
              separatorBuilder: (_, _) => const VDivider(),
              itemBuilder: (context, index) {
                return VPagePadding(
                  horizontal: VSpacing.space2,
                  vertical: VSpacing.space2,
                  child: _SuggestionTile(
                    product: _suggestions[index],
                    onTap: () => _pick(_suggestions[index]),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Cùng chrome với overlay của `VCombobox`: viền `borderStrong`, radius card,
  /// shadow từ `VShadows` (không dùng Material elevation).
  Widget _panelShell(
    BuildContext context, {
    required Key key,
    required Widget child,
  }) {
    return KeyedSubtree(
      key: key,
      child: VOverlayMenuShell.panel(
        borderRadius: BorderRadius.circular(VRadius.card),
        borderSide: VBorders.side(context.vColors.borderStrong),
        boxShadow: _menuBoxShadow,
        padding: const EdgeInsets.symmetric(vertical: VSpacing.space0),
        child: child,
      ),
    );
  }

  List<Widget> _buildMenuChildren(BuildContext context, double menuWidth) {
    if (!_shouldShowMenu) return const [];

    return [
      Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _retainSearchFocus(),
        child: SizedBox(
          width: menuWidth,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: _menuMaxHeight),
            child: _buildMenuPanel(context),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final transparentMenuStyle = MenuStyle(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth = constraints.maxWidth;

        return Row(
          children: [
            Expanded(
              child: MenuButtonTheme(
                data: const MenuButtonThemeData(),
                child: MenuAnchor(
                  controller: _menuController,
                  clipBehavior: Clip.none,
                  style: transparentMenuStyle.copyWith(
                    minimumSize: WidgetStatePropertyAll(Size(menuWidth, 0)),
                    maximumSize: WidgetStatePropertyAll(
                      Size(menuWidth, _menuMaxHeight),
                    ),
                  ),
                  alignmentOffset: VOverlayMenuLayout.alignmentOffset,
                  reservedPadding: VOverlayMenuLayout.menuReservedPadding(_menuBoxShadow),
                  crossAxisUnconstrained: false,
                  onOpen: _handleMenuOpen,
                  onClose: _handleMenuClose,
                  menuChildren: _buildMenuChildren(context, menuWidth),
                  builder: (context, controller, child) {
                    return VSearchBar(
                      key: const Key('input_compose_product_search'),
                      controller: _controller,
                      focusNode: _focusNode,
                      hintText: 'Tìm tên, SKU hoặc barcode',
                      variant: VSearchBarVariant.outlined,
                      // Chỉ chiếm slot suffix khi đang fetch để nút xóa quay lại sau đó.
                      suffix: _phase == _SearchPhase.loading
                          ? const VLoading(size: 18, strokeWidth: 2)
                          : null,
                      onChanged: (value) {
                        setState(() {});
                        _onQueryChanged(value);
                      },
                      onSubmitted: _onSubmitted,
                      onClear: _clear,
                    );
                  },
                ),
              ),
            ),
            const VGap.horizontalSm(),
            VIconBox(
              key: const Key('btn_compose_scan_barcode'),
              icon: VIcons.qrCode,
              size: VTextField.controlHeight,
              iconSize: 22,
              backgroundColor: colors.surface,
              iconColor: colors.textBrand,
              borderColor: colors.borderDefault,
              borderRadius: VRadius.card,
              onTap: widget.onScanTap,
            ),
          ],
        );
      },
    );
  }
}

class _SearchErrorState extends StatelessWidget {
  const _SearchErrorState({
    required String? failureMessage,
    required Future<void> Function()? retry,
  }) : _failureMessage = failureMessage,
       _retry = retry;

  final String? _failureMessage;
  final Future<void> Function()? _retry;

  @override
  Widget build(BuildContext context) {
    return VEmptyState(
      tone: VComponentTone.danger,
      padding: const EdgeInsets.all(VSpacing.space2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VEmptyHeader(
            children: [
              const VEmptyMedia(icon: VIcons.warning),
              const VEmptyTitle('Không thể tìm sản phẩm'),
              VEmptyDescription(
                _failureMessage ?? 'Kiểm tra kết nối và thử lại.',
              ),
            ],
          ),
          const VGap(VSpacing.space2),
          VEmptyContent(
            child: VButton(
              key: const Key('btn_compose_search_retry'),
              label: 'Thử lại',
              variant: VButtonVariant.tertiary,
              leadingIcon: const VIcon(icon: VIcons.refresh, size: 18),
              onPressed: _retry == null ? null : () => _retry!(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return const VEmptyState(
      padding: EdgeInsets.all(VSpacing.space2),
      child: VEmptyHeader(
        children: [
          VEmptyMedia(icon: VIcons.search),
          VEmptyTitle('Không tìm thấy sản phẩm'),
          VEmptyDescription('Thử tên, SKU hoặc barcode khác.'),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.product, required this.onTap});

  final SalesSellableProductVm product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final base = product.baseUnitForSearch;
    final price = product.referencePrice;
    final priceLabel = price == null ? '—' : MoneyFormatter.format(amountMinor: price.amountMinor, currencyCode: price.currencyCode);
    final baseUnitLabel = base?.unitName ?? product.unitSummary;
    final stockLabel =
        product.stockQuantity?.toString() ??
        _digitsFromAvailability(product.availabilityLabel) ??
        '—';
    final tradeName = product.tradeName?.trim();
    final subtitle = tradeName == null || tradeName.isEmpty
        ? baseUnitLabel
        : '$tradeName · $baseUnitLabel';

    return VCard(
      key: Key('card_compose_suggest_${product.productId}'),
      onTap: product.isBlocked ? null : onTap,
      padding: const EdgeInsets.all(VSpacing.space3),
      border: Border(),
      borderRadius: VRadius.input,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VIconBox(
            icon: VIcons.image,
            size: 48,
            iconSize: 22,
            backgroundColor: colors.surfaceAlt,
            iconColor: colors.textMuted,
            borderRadius: VRadius.r8,
          ),
          const VGap.horizontalSm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  product.displayName,
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const VGap.xs(),
                VText(
                  subtitle,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const VGap.sm(),
                // Hàng dưới: Giá (trái) · ĐVT · Tồn (phải) — Hình 2.
                Row(
                  children: [
                    VText(
                      priceLabel,
                      variant: VTextVariant.bodyDefault,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    VText(
                      baseUnitLabel,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                    const VGap.horizontalMd(),
                    VText(
                      stockLabel,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _digitsFromAvailability(String? label) {
    if (label == null) return null;
    final match = RegExp(r'(\d+)').firstMatch(label);
    return match?.group(1);
  }
}
