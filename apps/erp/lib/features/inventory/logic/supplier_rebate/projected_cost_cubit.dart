import 'dart:async';

import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/projected_cost_state.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/rebate_rules.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectedCostCubit extends Cubit<ProjectedCostState> {
  final SupplierRebateRepository _rebates;
  final String _programId;
  final Duration _debounce;

  Timer? _debounceTimer;
  int _reqSeq = 0;

  ProjectedCostCubit({
    required SupplierRebateRepository rebates,
    required String programId,
    required List<ProgramProduct> products,
    Duration debounce = const Duration(milliseconds: 400),
  })  : _rebates = rebates,
        _programId = programId,
        _debounce = debounce,
        super(
          ProjectedCostState(
            productId: products.isNotEmpty ? products.first.productId : '',
          ),
        );

  num? _parseExtra(String raw) {
    final parsed = parseMoneyInput(raw);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  num? _parsePrice(String raw) {
    if (raw.trim().isEmpty) return null;
    return parseMoneyInput(raw);
  }

  Future<void> load() async {
    await _loadDefaultForCurrentProduct();
  }

  Future<void> selectProduct(String productId) async {
    if (productId == state.productId && !state.error && state.result != null) {
      return;
    }
    _debounceTimer?.cancel();
    emit(
      state.copyWith(
        productId: productId,
        priceText: '',
        clearResult: true,
        loading: true,
        error: false,
      ),
    );
    await _loadDefaultForCurrentProduct();
  }

  void setExtraQty(String value) {
    _debounceTimer?.cancel();
    emit(state.copyWith(extraText: value));
    if (state.productId.isEmpty) return;

    final trimmed = value.trim();
    if (trimmed.isNotEmpty && trimmed != '0' && _parseExtra(trimmed) == null) {
      return;
    }
    _debounceTimer = Timer(_debounce, _fetchProjection);
  }

  void setUnitPrice(String value) {
    _debounceTimer?.cancel();
    emit(state.copyWith(priceText: value));
    if (state.productId.isEmpty) return;

    final trimmed = value.trim();
    if (trimmed.isNotEmpty && _parsePrice(trimmed) == null) {
      return;
    }
    _debounceTimer = Timer(_debounce, _fetchProjection);
  }

  Future<void> _loadDefaultForCurrentProduct() async {
    if (state.productId.isEmpty) return;
    final seq = ++_reqSeq;
    final targetProduct = state.productId;
    emit(state.copyWith(loading: true, error: false));

    try {
      final res = await _rebates.projectedCost(
        programId: _programId,
        productId: targetProduct,
        extraQty: null,
        unitPrice: null,
      );
      if (isClosed || seq != _reqSeq || state.productId != targetProduct) {
        return;
      }
      final defaultText = res.defaultUnitPrice != null
          ? MoneyFormatter.formatMinorPlain(res.defaultUnitPrice!)
          : '';
      emit(
        state.copyWith(
          priceText: defaultText,
          result: res,
          loading: false,
          error: false,
        ),
      );

      final extra = _parseExtra(state.extraText);
      if (extra != null) {
        await _fetchProjection();
      }
    } catch (_) {
      if (isClosed || seq != _reqSeq || state.productId != targetProduct) {
        return;
      }
      emit(state.copyWith(loading: false, error: true));
    }
  }

  Future<void> _fetchProjection() async {
    if (state.productId.isEmpty) return;
    final seq = ++_reqSeq;
    final targetProduct = state.productId;
    final extra = _parseExtra(state.extraText);
    final price = _parsePrice(state.priceText);

    emit(state.copyWith(loading: true, error: false));
    try {
      final res = await _rebates.projectedCost(
        programId: _programId,
        productId: targetProduct,
        extraQty: extra,
        unitPrice: price,
      );
      if (isClosed || seq != _reqSeq || state.productId != targetProduct) {
        return;
      }
      emit(state.copyWith(result: res, loading: false, error: false));
    } catch (_) {
      if (isClosed || seq != _reqSeq || state.productId != targetProduct) {
        return;
      }
      emit(state.copyWith(loading: false, error: true));
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

