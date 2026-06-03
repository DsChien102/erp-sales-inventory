class EInvoiceSettingsState {
  final bool misaConnected;
  final String taxCode;
  final String username;
  final String password;
  final String appId;
  final DateTime? lastChecked;
  final String? updatedBy;
  final String? selectedTemplate;
  final bool autoIssue;
  final bool autoSend;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const EInvoiceSettingsState({
    this.misaConnected = false,
    this.taxCode = '',
    this.username = '',
    this.password = '',
    this.appId = '',
    this.lastChecked,
    this.updatedBy,
    this.selectedTemplate,
    this.autoIssue = false,
    this.autoSend = false,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  EInvoiceSettingsState copyWith({
    bool? misaConnected,
    String? taxCode,
    String? username,
    String? password,
    String? appId,
    DateTime? lastChecked,
    String? updatedBy,
    String? selectedTemplate,
    bool? autoIssue,
    bool? autoSend,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
  }) {
    return EInvoiceSettingsState(
      misaConnected: misaConnected ?? this.misaConnected,
      taxCode: taxCode ?? this.taxCode,
      username: username ?? this.username,
      password: password ?? this.password,
      appId: appId ?? this.appId,
      lastChecked: lastChecked ?? this.lastChecked,
      updatedBy: updatedBy ?? this.updatedBy,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      autoIssue: autoIssue ?? this.autoIssue,
      autoSend: autoSend ?? this.autoSend,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}
