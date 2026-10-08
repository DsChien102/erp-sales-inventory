import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/partner_action_log.dart';
import '../data/partner_repository.dart';
import 'partner_action_log_diff.dart';
import 'partner_change_history_state.dart';

class PartnerChangeHistoryCubit extends Cubit<PartnerChangeHistoryState> {
  PartnerChangeHistoryCubit({required PartnerRepository repository})
    : _repository = repository,
      super(const PartnerChangeHistoryState());

  final PartnerRepository _repository;

  Future<void> loadHistory(String partnerId) async {
    emit(state.copyWith(status: PartnerChangeHistoryStatus.loading));
    try {
      final page = await _repository.getActionLogs(partnerId);
      emit(
        state.copyWith(
          status: PartnerChangeHistoryStatus.success,
          items: page.items.map(_toEntry).toList(growable: false),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PartnerChangeHistoryStatus.failure,
          errorMessage: AppException.from(e).userMessage(),
        ),
      );
    }
  }

  void refresh(String partnerId) {
    emit(const PartnerChangeHistoryState());
    loadHistory(partnerId);
  }

  static PartnerChangeHistoryEntry _toEntry(PartnerActionLog item) {
    final actorId = item.actorUserId;
    final actorDisplay = actorId.length <= 8 ? actorId : actorId.substring(0, 8);
    final changes = PartnerActionLogDiff.compute(item.beforeState, item.afterState);
    return PartnerChangeHistoryEntry(
      id: item.actionLogId,
      occurredAt: item.createdAt,
      actorDisplayName: actorDisplay,
      changeType: item.actionType.name,
      summary: _summaryFor(item.actionType, changes),
      reason: item.reason,
      changes: changes,
    );
  }

  /// Max field labels named in an update title before collapsing to a count.
  static const _summaryLabelLimit = 2;

  static String _summaryFor(PartnerActionType type, List<PartnerFieldChange> changes) {
    if (type == PartnerActionType.update && changes.isNotEmpty) {
      final labels = changes.map((c) => _titleLabel(c.label)).toList(growable: false);
      if (labels.length <= _summaryLabelLimit) {
        return 'Cập nhật ${labels.join(', ')}';
      }
      final visible = labels.take(_summaryLabelLimit).join(', ');
      final remaining = labels.length - _summaryLabelLimit;
      return 'Cập nhật $visible và $remaining thông tin khác';
    }
    return switch (type) {
      PartnerActionType.create => 'Tạo đối tác',
      PartnerActionType.update => 'Cập nhật',
      PartnerActionType.addContact => 'Thêm người liên hệ',
      PartnerActionType.removeContact => 'Xóa người liên hệ',
      PartnerActionType.transform => 'Chuyển sang tổ chức',
      PartnerActionType.deactivate => 'Ngừng hoạt động',
      PartnerActionType.reactivate => 'Kích hoạt lại',
      PartnerActionType.delete => 'Xóa đối tác',
    };
  }

  /// Sentence-cases a field label for use mid-title: lowercases the first
  /// letter unless the label starts with an acronym (SĐT, MST, ...).
  static String _titleLabel(String label) {
    if (label.length < 2) return label.toLowerCase();
    final startsWithAcronym = label.substring(0, 2) == label.substring(0, 2).toUpperCase();
    if (startsWithAcronym) return label;
    return label[0].toLowerCase() + label.substring(1);
  }
}
