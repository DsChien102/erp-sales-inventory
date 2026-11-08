import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/features/einvoice/data/einvoice_configuration_repository.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/einvoice_repository.dart';
import 'package:erp/features/einvoice/data/models.dart';

import 'einvoice_error_messages.dart';
import 'order_einvoice_idempotency_key_factory.dart';
import 'order_einvoice_refresh_snapshot.dart';
import 'order_einvoice_state.dart';
import 'package:erp/features/einvoice/data/i_invoice_viewer_launcher.dart';
import 'package:erp/features/einvoice/data/i_invoice_document_exporter.dart';
import 'package:erp/features/einvoice/data/file_invoice_document_exporter.dart';
import 'package:erp/features/einvoice/data/url_invoice_viewer_launcher.dart';

class OrderEInvoiceCubit extends Cubit<OrderEInvoiceState> {
  OrderEInvoiceCubit({
    required String salesOrderId,
    required int orderVersion,
    required OrderInvoiceProjectionDto initialProjection,
    IssuanceReadinessDto? initialReadiness,
    bool isBuyerNotReady = false,
    bool hasLoadedInitialProjection = true,
    required EInvoiceRepository repository,
    required EInvoiceConfigurationRepository configurationRepository,
    IInvoiceViewerLauncher? viewerLauncher,
    IInvoiceDocumentExporter? documentExporter,
    OrderEInvoiceIdempotencyKeyFactory idempotencyKeyFactory =
        const OrderEInvoiceIdempotencyKeyFactory(),
    this.pollInterval = const Duration(seconds: 5),
  }) : _repository = repository,
       _configurationRepository = configurationRepository,
       _viewerLauncher = viewerLauncher ?? const UrlInvoiceViewerLauncher(),
       _documentExporter = documentExporter ?? const FileInvoiceDocumentExporter(),
       _idempotencyKeys = idempotencyKeyFactory,
       super(
         OrderEInvoiceState(
           salesOrderId: salesOrderId,
           orderVersion: orderVersion,
           projection: initialProjection,
           readiness: initialReadiness,
           isBuyerNotReady: isBuyerNotReady,
           hasLoadedProjection: hasLoadedInitialProjection,
         ),
       );

  final EInvoiceRepository _repository;
  final EInvoiceConfigurationRepository _configurationRepository;
  final IInvoiceViewerLauncher _viewerLauncher;
  final IInvoiceDocumentExporter _documentExporter;
  final OrderEInvoiceIdempotencyKeyFactory _idempotencyKeys;
  final Duration pollInterval;

  Timer? _pollTimer;
  Future<OrderEInvoiceRefreshSnapshot>? _inFlight;
  int _previewGeneration = 0;

  /// Triggered when user confirms issue/retry action on UI.
  Future<void> issueOrRetry() async {
    final currentState = state;
    emit(currentState.copyWith(status: OrderEInvoiceStatus.submitting));

    try {
      final key = _idempotencyKeys.next();

      if (currentState.projection.issuanceDisplayState == IssuanceDisplayState.failed) {
        // Retry from failed
        await _repository.retry(
          salesOrderId: currentState.salesOrderId,
          expectedOrderVersion: currentState.orderVersion,
          idempotencyKey: key,
        );
      } else {
        // Normal issue
        await _repository.issue(
          salesOrderId: currentState.salesOrderId,
          sourceVersion: currentState.orderVersion.toString(),
          idempotencyKey: key,
        );
      }

      emit(state.toProcessing());
      await refresh();
    } catch (e) {
      emit(
        state.copyWith(
          status: OrderEInvoiceStatus.error,
          errorMessage: einvoiceErrorMessage(e),
        ),
      );
    }
  }

  /// Alias for issueOrRetry for explicit issue action.
  Future<void> issueNow() => issueOrRetry();

  Future<OrderEInvoiceRefreshSnapshot> _read() {
    _inFlight ??= _loadRefreshSnapshot().whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  Future<void> _pollOnce() async {
    if (isClosed || !state.isPageActive) return;
    try {
      final snapshot = await _read();
      if (!isClosed) {
        _applyRefreshSnapshot(snapshot);
      }
    } catch (_) {}
  }

  /// Projection, readiness, and safe attempt-status refresh.
  Future<void> refresh() async {
    if (isClosed || !state.isPageActive) {
      return;
    }

    try {
      final snapshot = await _read();
      if (!isClosed) {
        _applyRefreshSnapshot(snapshot);
      }
    } catch (_) {
      // Lỗi đọc tạm thời không được thay thế projection đáng tin cậy gần nhất.
    }
  }

  void setPollingActive(bool active) {
    if (!active) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    if (_pollTimer == null && !isClosed) {
      unawaited(_pollOnce());
      _pollTimer = Timer.periodic(pollInterval, (_) => unawaited(_pollOnce()));
    }
  }

  @override
  Future<void> close() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    return super.close();
  }

  Future<OrderEInvoiceRefreshSnapshot> _loadRefreshSnapshot() async {
    final projection = await _repository.getProjection(state.salesOrderId);

    IssuanceReadinessDto? readiness;
    try {
      readiness = await _repository.getReadiness(state.salesOrderId);
    } catch (_) {}

    IssuanceAttemptStatusDto? attemptStatus;
    if (projection.issuanceDisplayState == IssuanceDisplayState.failed) {
      try {
        attemptStatus = await _repository.getAttemptStatus(state.salesOrderId);
      } catch (_) {}
    }

    return OrderEInvoiceRefreshSnapshot(
      projection: projection,
      readiness: readiness,
      attemptStatus: attemptStatus,
    );
  }

  void _applyRefreshSnapshot(OrderEInvoiceRefreshSnapshot snapshot) {
    if (isClosed || !state.isPageActive) return;
    final blockers = snapshot.readiness?.blockers ?? const [];
    final buyerNotReady = snapshot.readiness == null
        ? state.isBuyerNotReady
        : blockers.any(
            (blocker) =>
                blocker.code == EInvoiceErrorCodes.buyerTaxCodeRequired ||
                blocker.code == EInvoiceErrorCodes.buyerDataIncomplete ||
                blocker.code == 'BUYER_SOURCE_UNAVAILABLE',
          );
    final failure = snapshot.attemptStatus;
    emit(
      state.copyWith(
        status: state.status == OrderEInvoiceStatus.submitting ? OrderEInvoiceStatus.idle : null,
        projection: snapshot.projection,
        readiness: snapshot.readiness ?? state.readiness,
        isBuyerNotReady: buyerNotReady,
        hasLoadedProjection: true,
        failureCode: failure?.failureCode,
        lastFailureMessage: failure?.lastErrorMessage,
        clearError: true,
        clearFailure: failure == null,
      ),
    );
  }

  /// Loads the saved default template for the confirmation sheet.
  ///
  /// Returns false when the issuance profile has no template. A failed profile
  /// read returns true so a transient error does not block the sheet.
  Future<bool> ensureIssuanceTemplateDisplay() async {
    try {
      final template = await _loadIssuanceTemplateDisplay();
      if (template.saved == false) return false;
      emit(
        state.copyWith(
          templateNumber: template.number,
          templateSymbol: template.symbol,
          authorityMode: template.authority,
        ),
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<({bool? saved, String number, String symbol, String authority})>
  _loadIssuanceTemplateDisplay() async {
    IssuanceProfileDto? profile;
    var profileLoaded = false;
    List<ProviderTemplateDto> templates = const [];
    try {
      profile = await _configurationRepository.getIssuanceProfile();
      profileLoaded = true;
    } catch (_) {}
    try {
      templates = await _configurationRepository.listTemplates();
    } catch (_) {}

    ProviderTemplateDto? selected;
    final templateId = profile?.templateId;
    if (templateId != null && templateId.isNotEmpty) {
      for (final item in templates) {
        if (item.templateId == templateId) {
          selected = item;
          break;
        }
      }
    }
    if (selected == null) {
      for (final item in templates) {
        final hasSymbol = item.symbol != null && item.symbol!.trim().isNotEmpty;
        final hasSerial = item.serial != null && item.serial!.trim().isNotEmpty;
        if (hasSymbol || hasSerial) {
          selected = item;
          break;
        }
      }
    }
    selected ??= templates.isEmpty ? null : templates.first;

    final symbol = selected?.symbol?.trim();
    final serial = selected?.serial?.trim();
    final savedTemplateId = profile?.templateId?.trim();
    return (
      saved: profileLoaded
          ? savedTemplateId != null && savedTemplateId.isNotEmpty
          : null,
      number: (serial != null && serial.isNotEmpty) ? serial : '—',
      symbol: (symbol != null && symbol.isNotEmpty)
          ? symbol
          : ((serial != null && serial.isNotEmpty) ? serial : '—'),
      authority: _authorityModeLabel(profile?.signingMethod),
    );
  }

  static String _authorityModeLabel(SigningMethod? method) {
    return switch (method) {
      SigningMethod.hsm => 'Có mã CQT',
      SigningMethod.mtt => 'Máy tính tiền',
      SigningMethod.noSign => 'Không ký',
      null => '—',
    };
  }

  /// Cancels an in-flight preview (e.g. user dismisses the pre-issue sheet).
  ///
  /// Stops client-side polling / launch; does not revoke a server request that
  /// already started. No-op when not [OrderEInvoiceStatus.previewing].
  void cancelPreview() {
    _previewGeneration++;
    if (!isClosed && state.status == OrderEInvoiceStatus.previewing) {
      emit(
        state.copyWith(
          status: OrderEInvoiceStatus.idle,
          clearError: true,
        ),
      );
    }
  }

  /// Requests preview, polls for readiness if needed, and launches viewer.
  ///
  /// Default poll window is ~45s (45 × 1s) so MISA unpublished preview can
  /// finish before the UI surfaces a false "not ready" error. Concurrent taps
  /// while [OrderEInvoiceStatus.previewing] are ignored. A previous
  /// [OrderEInvoiceState.previewViewerUrl] is kept until a new URL arrives.
  /// Call [cancelPreview] to abort after sheet dismiss.
  Future<String?> requestPreview({
    int maxPollAttempts = 45,
    Duration pollDelay = const Duration(seconds: 1),
  }) async {
    if (state.status == OrderEInvoiceStatus.previewing) {
      return null;
    }

    final generation = ++_previewGeneration;
    emit(
      state.copyWith(
        status: OrderEInvoiceStatus.previewing,
        clearError: true,
      ),
    );
    try {
      if (!_isPreviewGenerationCurrent(generation)) return null;

      final result = await _repository.requestPreview(
        salesOrderId: state.salesOrderId,
        expectedOrderVersion: state.orderVersion,
      );
      if (!_isPreviewGenerationCurrent(generation)) return null;

      var viewerUrl = _nonEmptyViewerRef(result.viewerRef);
      if (viewerUrl == null) {
        var delay = pollDelay;
        for (var i = 0; i < maxPollAttempts; i++) {
          await Future<void>.delayed(delay);
          if (!_isPreviewGenerationCurrent(generation)) return null;
          try {
            final preview = await _repository.getPreview(state.salesOrderId);
            if (!_isPreviewGenerationCurrent(generation)) return null;
            viewerUrl = _nonEmptyViewerRef(preview.viewerRef);
            if (viewerUrl != null) {
              break;
            }
          } catch (_) {
            // Transient poll failures should not abort the window.
          }
          // Mild backoff: 1s → 1.25s → … capped at 2s (skip when delay is 0 in tests).
          if (delay > Duration.zero) {
            final nextMs = (delay.inMilliseconds + 250).clamp(
              pollDelay.inMilliseconds,
              2000,
            );
            delay = Duration(milliseconds: nextMs);
          }
        }
      }

      if (!_isPreviewGenerationCurrent(generation)) return null;

      if (viewerUrl != null) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.idle,
            previewViewerUrl: viewerUrl,
            clearError: true,
          ),
        );
        await _viewerLauncher.launch(viewerUrl);
        return viewerUrl;
      }

      emit(
        state.copyWith(
          status: OrderEInvoiceStatus.error,
          errorMessage: 'Xem trước hóa đơn chưa sẵn sàng. Vui lòng thử lại sau ít giây.',
        ),
      );
      return null;
    } catch (e) {
      if (!_isPreviewGenerationCurrent(generation)) return null;
      emit(
        state.copyWith(
          status: OrderEInvoiceStatus.error,
          errorMessage: einvoiceErrorMessage(e),
        ),
      );
      return null;
    }
  }

  bool _isPreviewGenerationCurrent(int generation) => !isClosed && generation == _previewGeneration;

  static String? _nonEmptyViewerRef(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  /// Opens the official signed invoice viewer, polling while the worker builds it.
  Future<bool> openOfficialView({
    int maxPollAttempts = 12,
    Duration pollDelay = const Duration(milliseconds: 1500),
  }) async {
    if (state.isOpeningOfficialView) return false;
    if (state.projection.issuanceDisplayState != IssuanceDisplayState.issued) {
      return false;
    }

    emit(
      state.copyWith(
        isOpeningOfficialView: true,
        clearError: true,
        clearOfficialViewerUrl: true,
      ),
    );
    try {
      final result = await _repository.requestOfficialView(state.salesOrderId);
      if (isClosed) return false;

      var viewerUrl = _nonEmptyViewerRef(result.viewerUrl);
      final operationId = result.operationId?.trim();
      final commandStatus = result.status;

      if (viewerUrl == null &&
          (commandStatus == InvoiceDocumentStatus.failed ||
              commandStatus == InvoiceDocumentStatus.checkRequired)) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.error,
            errorMessage: _officialViewUnavailableMessage,
          ),
        );
        return false;
      }

      final shouldPoll =
          viewerUrl == null &&
          operationId != null &&
          operationId.isNotEmpty &&
          (commandStatus == InvoiceDocumentStatus.pending ||
              commandStatus == InvoiceDocumentStatus.available);

      if (shouldPoll) {
        var delay = commandStatus == InvoiceDocumentStatus.available ? Duration.zero : pollDelay;
        InvoiceDocumentStatus? matchedStatus;

        for (var i = 0; i < maxPollAttempts; i++) {
          if (isClosed) return false;
          if (delay > Duration.zero) {
            await Future<void>.delayed(delay);
          }
          if (isClosed) return false;

          try {
            final detail = await _repository.getDetail(state.salesOrderId);
            if (isClosed) return false;

            if (detail.officialViewOperationId != operationId) {
              // Stale generation — keep polling without adopting URL/status.
            } else {
              matchedStatus = detail.officialViewStatus;
              viewerUrl = _nonEmptyViewerRef(detail.officialViewerUrl);
              if (viewerUrl != null ||
                  matchedStatus == InvoiceDocumentStatus.failed ||
                  matchedStatus == InvoiceDocumentStatus.checkRequired ||
                  matchedStatus == InvoiceDocumentStatus.available) {
                break;
              }
            }
          } catch (_) {
            // Transient poll failures should not abort the window.
          }

          if (delay == Duration.zero) {
            delay = pollDelay;
          } else if (delay > Duration.zero) {
            final nextMs = (delay.inMilliseconds * 1.5).clamp(1500, 5000).toInt();
            delay = Duration(milliseconds: nextMs);
          }
        }

        if (viewerUrl == null &&
            (matchedStatus == InvoiceDocumentStatus.failed ||
                matchedStatus == InvoiceDocumentStatus.checkRequired)) {
          if (!isClosed) {
            emit(
              state.copyWith(
                status: OrderEInvoiceStatus.error,
                errorMessage: _officialViewUnavailableMessage,
              ),
            );
          }
          return false;
        }
      }

      if (isClosed) return false;

      if (viewerUrl != null) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.idle,
            officialViewerUrl: viewerUrl,
          ),
        );
        final launched = await _viewerLauncher.launch(viewerUrl);
        if (!launched && !isClosed) {
          emit(
            state.copyWith(
              status: OrderEInvoiceStatus.error,
              errorMessage: 'Không thể mở liên kết xem hóa đơn trên thiết bị.',
            ),
          );
        }
        return launched;
      }
      emit(
        state.copyWith(
          status: OrderEInvoiceStatus.error,
          errorMessage: 'Đang tải bản thể hiện hóa đơn. Vui lòng thử lại sau giây lát.',
        ),
      );
      return false;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.error,
            errorMessage: einvoiceErrorMessage(e),
          ),
        );
      }
      return false;
    } finally {
      if (!isClosed && state.isOpeningOfficialView) {
        emit(state.copyWith(isOpeningOfficialView: false));
      }
    }
  }

  static const _officialViewUnavailableMessage =
      'Không thể mở bản thể hiện hóa đơn lúc này. Vui lòng thử lại.';

  /// Downloads PDF or XML document, polling while the worker prepares it.
  Future<bool> downloadDocument(
    InvoiceDocumentType type, {
    int maxPollAttempts = 15,
    Duration pollDelay = const Duration(milliseconds: 1500),
  }) async {
    if (state.downloadingDocumentType != null) return false;
    if (state.projection.issuanceDisplayState != IssuanceDisplayState.issued) {
      return false;
    }

    emit(
      state.copyWith(
        status: OrderEInvoiceStatus.downloading,
        downloadingDocumentType: type,
        clearError: true,
      ),
    );
    try {
      final result = await _repository.requestDocument(
        salesOrderId: state.salesOrderId,
        documentType: type,
      );
      if (isClosed) return false;

      var downloadUrl = _nonEmptyViewerRef(result.downloadUrl);
      var checksum = _nonEmptyViewerRef(result.checksum);
      final operationId = result.operationId?.trim();
      final commandStatus = result.status;

      if (downloadUrl == null &&
          (commandStatus == InvoiceDocumentStatus.failed ||
              commandStatus == InvoiceDocumentStatus.checkRequired)) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.error,
            errorMessage: _documentUnavailableMessage,
          ),
        );
        return false;
      }

      final shouldPoll =
          downloadUrl == null &&
          operationId != null &&
          operationId.isNotEmpty &&
          (commandStatus == InvoiceDocumentStatus.pending ||
              commandStatus == InvoiceDocumentStatus.available);

      InvoiceDocumentStatus? matchedStatus;
      if (shouldPoll) {
        var delay = commandStatus == InvoiceDocumentStatus.available ? Duration.zero : pollDelay;

        for (var i = 0; i < maxPollAttempts; i++) {
          if (isClosed) return false;
          if (delay > Duration.zero) {
            await Future<void>.delayed(delay);
          }
          if (isClosed) return false;

          try {
            final documents = await _repository.getDocuments(state.salesOrderId);
            if (isClosed) return false;

            final item = type == InvoiceDocumentType.pdf ? documents.pdf : documents.xml;
            if (item == null || item.operationId != operationId) {
              // Missing or stale generation — keep polling.
            } else {
              matchedStatus = item.status;
              downloadUrl = _nonEmptyViewerRef(item.downloadUrl);
              checksum = _nonEmptyViewerRef(item.checksum) ?? checksum;
              if (downloadUrl != null ||
                  matchedStatus == InvoiceDocumentStatus.failed ||
                  matchedStatus == InvoiceDocumentStatus.checkRequired ||
                  matchedStatus == InvoiceDocumentStatus.available) {
                break;
              }
            }
          } catch (_) {
            // Transient poll failures should not abort the window.
          }

          if (delay == Duration.zero) {
            delay = pollDelay;
          } else if (delay > Duration.zero) {
            final nextMs = (delay.inMilliseconds * 1.5).clamp(1500, 5000).toInt();
            delay = Duration(milliseconds: nextMs);
          }
        }

        if (downloadUrl == null &&
            (matchedStatus == InvoiceDocumentStatus.failed ||
                matchedStatus == InvoiceDocumentStatus.checkRequired)) {
          if (!isClosed) {
            emit(
              state.copyWith(
                status: OrderEInvoiceStatus.error,
                errorMessage: _documentUnavailableMessage,
              ),
            );
          }
          return false;
        }
      }

      if (isClosed) return false;

      final isAvailable =
          matchedStatus == InvoiceDocumentStatus.available ||
          commandStatus == InvoiceDocumentStatus.available;

      if (downloadUrl != null && checksum != null) {
        final ext = type == InvoiceDocumentType.pdf ? 'pdf' : 'xml';
        final filename = 'invoice_${state.salesOrderId}.$ext';

        final success = await _documentExporter.exportDocument(
          filename: filename,
          type: type,
          url: downloadUrl,
          expectedSha256: checksum,
        );

        if (!success) {
          if (!isClosed) {
            emit(
              state.copyWith(
                status: OrderEInvoiceStatus.error,
                errorMessage: 'Không thể lưu tài liệu hóa đơn trên thiết bị. Vui lòng thử lại.',
              ),
            );
          }
          return false;
        }

        if (!isClosed) {
          emit(state.copyWith(status: OrderEInvoiceStatus.idle));
        }
        return success;
      }

      // AVAILABLE without URL/checksum, or URL without checksum — fail closed.
      if (isAvailable || downloadUrl != null) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: OrderEInvoiceStatus.error,
              errorMessage: _documentUnavailableMessage,
            ),
          );
        }
        return false;
      }

      if (!isClosed) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.error,
            errorMessage: 'Đang chuẩn bị tài liệu hóa đơn. Vui lòng thử lại sau giây lát.',
          ),
        );
      }
      return false;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: OrderEInvoiceStatus.error,
            errorMessage: einvoiceErrorMessage(e),
          ),
        );
      }
      return false;
    } finally {
      if (!isClosed && state.downloadingDocumentType != null) {
        emit(state.copyWith(clearDownloadingDocumentType: true));
      }
    }
  }

  static const _documentUnavailableMessage =
      'Không thể tải tài liệu hóa đơn lúc này. Vui lòng thử lại.';

  /// Control whether auto-refresh is active (pauses when page inactive).
  void setPageActive(bool isActive) {
    emit(state.copyWith(isPageActive: isActive));
  }
}
