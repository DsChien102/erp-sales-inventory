import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/models/lot_date.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_count_cubit.dart';
import 'package:erp/features/inventory/presentation/patterns/expiry_date_field.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Sheet "Thêm hàng thực tế" cho SCR-044 (Q-5-5: chỉ sản phẩm đã có giá vốn, không tình trạng).
Future<StocktakeLine?> showStocktakeUnexpectedSheet(
  BuildContext context, {
  required StocktakeCountCubit cubit,
}) {
  return showVAdaptiveSheet<StocktakeLine>(
    context: context,
    title: 'Thêm hàng thực tế',
    child: _StocktakeUnexpectedSheetBody(cubit: cubit),
  );
}

class _StocktakeUnexpectedSheetBody extends StatefulWidget {
  const _StocktakeUnexpectedSheetBody({required this.cubit});

  final StocktakeCountCubit cubit;

  @override
  State<_StocktakeUnexpectedSheetBody> createState() =>
      _StocktakeUnexpectedSheetBodyState();
}

class _StocktakeUnexpectedSheetBodyState
    extends State<_StocktakeUnexpectedSheetBody> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _lotCodeController = TextEditingController();

  bool _loading = true;
  String? _loadError;
  StocktakeUnexpectedOptions? _options;
  String _query = '';
  StocktakeUnexpectedProduct? _selectedProduct;
  String _expiryRaw = '';
  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _lotCodeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final opts = await widget.cubit.fetchUnexpectedOptions();
      if (!mounted) return;
      setState(() {
        _options = opts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final appError = AppException.from(e);
      setState(() {
        _loading = false;
        _loadError = inventoryErrorMessage(
          appError,
          fallback: appError.userMessage(),
        );
      });
    }
  }

  Future<void> _submit({
    required StocktakeUnexpectedProduct product,
    String? lotId,
    String? lotCode,
    DateTime? expiryDate,
    String? expiryPrecision,
  }) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final line = await widget.cubit.addUnexpected(
        productId: product.id,
        lotId: lotId,
        lotCode: lotCode,
        expiryDate: expiryDate,
        expiryPrecision: expiryPrecision,
      );
      if (!mounted) return;
      Navigator.of(context).pop(line);
    } catch (e) {
      if (!mounted) return;
      final appError = AppException.from(e);
      setState(() {
        _submitting = false;
        _submitError = inventoryErrorMessage(
          appError,
          fallback: appError.userMessage(),
        );
      });
    }
  }

  String _precisionWire(DatePrecision p) => switch (p) {
    DatePrecision.day => 'DAY',
    DatePrecision.month => 'MONTH',
    DatePrecision.year => 'YEAR',
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(VSpacing.space4),
        child: InventoryLoading(
          blocks: [
            InventorySkeletonBlock.search,
            InventorySkeletonBlock.row,
            InventorySkeletonBlock.row,
          ],
        ),
      );
    }

    if (_loadError != null || _options == null) {
      return Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: InventoryEmpty(
          title: 'Không tải được sản phẩm',
          description: _loadError ?? 'Kiểm tra kết nối rồi thử lại.',
          actionLabel: 'Thử lại',
          onAction: _load,
        ),
      );
    }

    if (_selectedProduct != null) {
      return _buildLotStep(_selectedProduct!);
    }

    final products = _options!.products;
    final normalized = VTextNormalizer.normalizeForSearch(_query.trim());
    final filtered = products.where((p) {
      if (normalized.isEmpty) return true;
      final hay = VTextNormalizer.normalizeForSearch(
        '${p.name} ${p.code} ${p.uom}',
      );
      return hay.contains(normalized);
    }).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_submitError != null) ...[
            VBanner(tone: VComponentTone.warning, title: _submitError!),
            const SizedBox(height: VSpacing.space3),
          ],
          VSearchBar(
            controller: _searchController,
            hintText: 'Tìm hoặc quét sản phẩm',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: VSpacing.space3),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: VSpacing.space4),
              child: InventoryEmpty(
                title: 'Không còn sản phẩm để thêm',
                description: 'Chỉ thêm được sản phẩm đã từng nhập kho.',
              ),
            )
          else if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: VSpacing.space4),
              child: InventoryEmpty(
                title: 'Không tìm thấy sản phẩm',
                description: 'Thử mã hoặc tên khác.',
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: VSpacing.space2),
                itemBuilder: (context, index) {
                  final product = filtered[index];
                  return VListRow(
                    title: product.name,
                    subtitle: '${product.code} · ${product.uom}',
                    onTap: _submitting
                        ? null
                        : () {
                            if (product.isLotTracked) {
                              setState(() {
                                _selectedProduct = product;
                                _submitError = null;
                              });
                            } else {
                              _submit(product: product);
                            }
                          },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLotStep(StocktakeUnexpectedProduct product) {
    final lotCode = _lotCodeController.text.trim();
    final trimmedExpiry = _expiryRaw.trim();
    final parsedExpiry = trimmedExpiry.isEmpty
        ? null
        : LotDate.tryParseAuto(trimmedExpiry);
    final expiryInvalid = trimmedExpiry.isNotEmpty && parsedExpiry == null;
    final canSubmitNewLot =
        !_submitting && lotCode.isNotEmpty && !expiryInvalid;

    return Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            product.name,
            variant: VTextVariant.headingH4,
            color: context.vColors.textPrimary,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: VSpacing.space3),
          if (_submitError != null) ...[
            VBanner(tone: VComponentTone.warning, title: _submitError!),
            const SizedBox(height: VSpacing.space3),
          ],
          if (product.lots.isNotEmpty) ...[
            VText(
              'Chọn lô sẵn có',
              variant: VTextVariant.bodySmall,
              color: context.vColors.textSecondary,
            ),
            const SizedBox(height: VSpacing.space2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: product.lots.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: VSpacing.space2),
                itemBuilder: (context, index) {
                  final lot = product.lots[index];
                  return VListRow(
                    title: 'Lô ${lot.lotCode}',
                    subtitle: product.code,
                    onTap: _submitting
                        ? null
                        : () => _submit(product: product, lotId: lot.id),
                  );
                },
              ),
            ),
            const SizedBox(height: VSpacing.space4),
          ],
          VField(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const VFieldLabel('Lô', isRequired: true),
                const SizedBox(height: VSpacing.space1),
                VTextField(
                  controller: _lotCodeController,
                  hintText: 'Nhập mã lô mới',
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.space3),
          InventoryExpiryField(
            label: 'Hạn dùng',
            errorText: 'Định dạng dd/mm/yyyy, mm/yyyy hoặc yyyy',
            value: _expiryRaw,
            onChanged: (v) => setState(() => _expiryRaw = v),
          ),
          const SizedBox(height: VSpacing.space4),
          Row(
            children: [
              Expanded(
                child: VButton(
                  label: 'Quay lại',
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: _submitting
                      ? null
                      : () => setState(() {
                            _selectedProduct = null;
                            _submitError = null;
                          }),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Expanded(
                child: VButton(
                  label: 'Thêm vào phiên',
                  variant: VButtonVariant.primary,
                  fullWidth: true,
                  onPressed: canSubmitNewLot
                      ? () => _submit(
                          product: product,
                          lotCode: lotCode,
                          expiryDate: parsedExpiry?.start,
                          expiryPrecision: parsedExpiry != null
                              ? _precisionWire(parsedExpiry.precision)
                              : null,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

