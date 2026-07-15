import 'package:flutter_bloc/flutter_bloc.dart';
import 'partner_change_history_state.dart';

class PartnerChangeHistoryCubit extends Cubit<PartnerChangeHistoryState> {
  PartnerChangeHistoryCubit() : super(const PartnerChangeHistoryState());

  Future<void> loadHistory(String partnerId) async {
    emit(state.copyWith(status: PartnerChangeHistoryStatus.loading));
    
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 600));

    final now = DateTime.now();
    final items = [
      PartnerChangeHistoryEntry(
        id: 'h-1',
        occurredAt: now.subtract(const Duration(hours: 5)),
        actorDisplayName: '8acac7ec',
        changeType: 'add_contact',
        summary: 'Thêm người liên hệ chính',
        valueAfter: 'Nguyễn Văn B',
      ),
      PartnerChangeHistoryEntry(
        id: 'h-2',
        occurredAt: now.subtract(const Duration(days: 1)),
        actorDisplayName: '8acac7ec',
        changeType: 'update',
        summary: 'Cập nhật số điện thoại',
        valueBefore: '0901234567',
        valueAfter: '0912345678',
      ),
      PartnerChangeHistoryEntry(
        id: 'h-3',
        occurredAt: now.subtract(const Duration(days: 2)),
        actorDisplayName: '8acac7ec',
        changeType: 'create',
        summary: 'Tạo đối tác',
      ),
    ];

    emit(state.copyWith(
      status: PartnerChangeHistoryStatus.success,
      items: items,
    ));
  }

  void refresh(String partnerId) {
    emit(const PartnerChangeHistoryState());
    loadHistory(partnerId);
  }
}
