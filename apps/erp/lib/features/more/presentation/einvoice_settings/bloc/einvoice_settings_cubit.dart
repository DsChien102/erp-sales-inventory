import 'package:flutter_bloc/flutter_bloc.dart';
import 'einvoice_settings_state.dart';

class EInvoiceSettingsCubit extends Cubit<EInvoiceSettingsState> {
  EInvoiceSettingsCubit() : super(const EInvoiceSettingsState());

  // Static/shared state simulation so it persists across screen navigations
  static EInvoiceSettingsState _persistedState = const EInvoiceSettingsState(
    misaConnected: false,
    taxCode: '',
    username: '',
    password: '',
    appId: '',
    autoIssue: false,
    autoSend: false,
  );

  Future<void> loadSettings() async {
    emit(state.copyWith(isLoading: true));
    await Future.delayed(const Duration(milliseconds: 300));
    emit(_persistedState.copyWith(isLoading: false));
  }

  Future<bool> saveConnection({
    required String taxCode,
    required String username,
    required String password,
    required String appId,
  }) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null));
    
    // Simulate API request to MISA meInvoice
    await Future.delayed(const Duration(milliseconds: 1500));

    if (taxCode.trim().isEmpty || username.trim().isEmpty || password.isEmpty || appId.trim().isEmpty) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Vui lòng nhập đầy đủ tất cả các trường bắt buộc',
      ));
      return false;
    }

    if (taxCode.length < 10) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Mã số thuế không hợp lệ. Vui lòng nhập ít nhất 10 ký tự',
      ));
      return false;
    }

    final updatedState = state.copyWith(
      misaConnected: true,
      taxCode: taxCode,
      username: username,
      password: password,
      appId: appId,
      lastChecked: DateTime.now(),
      updatedBy: 'Nguyễn Thu Hà',
      isSubmitting: false,
      successMessage: 'Kết nối dịch vụ MISA meInvoice thành công!',
    );

    _persistedState = updatedState;
    emit(updatedState);
    return true;
  }

  Future<bool> saveTemplate(String template) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null));
    await Future.delayed(const Duration(milliseconds: 1000));

    final updatedState = state.copyWith(
      selectedTemplate: template,
      isSubmitting: false,
      successMessage: 'Đã lưu mẫu hóa đơn mặc định',
    );

    _persistedState = updatedState;
    emit(updatedState);
    return true;
  }

  Future<bool> saveAutoSettings({
    required bool autoIssue,
    required bool autoSend,
  }) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null));
    await Future.delayed(const Duration(milliseconds: 1000));

    final updatedState = state.copyWith(
      autoIssue: autoIssue,
      autoSend: autoSend,
      isSubmitting: false,
      successMessage: 'Đã lưu cấu hình tự động phát hành và gửi',
    );

    _persistedState = updatedState;
    emit(updatedState);
    return true;
  }

  Future<bool> retestConnection() async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null));
    await Future.delayed(const Duration(milliseconds: 1500));

    final updatedState = state.copyWith(
      misaConnected: true,
      lastChecked: DateTime.now(),
      updatedBy: 'Nguyễn Thu Hà',
      isSubmitting: false,
      successMessage: 'Kiểm tra kết nối thành công!',
    );

    _persistedState = updatedState;
    emit(updatedState);
    return true;
  }

  Future<bool> disconnect() async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null));
    await Future.delayed(const Duration(milliseconds: 1000));

    final updatedState = EInvoiceSettingsState(
      misaConnected: false,
      taxCode: state.taxCode,
      username: state.username,
      password: '', // Clear password field
      appId: state.appId,
      selectedTemplate: state.selectedTemplate,
      autoIssue: state.autoIssue,
      autoSend: state.autoSend,
      lastChecked: null,
      updatedBy: null,
      isSubmitting: false,
      successMessage: 'Đã ngắt kết nối MISA meInvoice',
    );

    _persistedState = updatedState;
    emit(updatedState);
    return true;
  }

  void clearMessages() {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }
}
