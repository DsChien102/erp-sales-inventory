import '../../../core/errors/app_exception.dart';
import '../data/models/home_summary.dart';

enum HomeStatus { loading, ready, error }

final class HomeState {
  const HomeState({
    this.status = HomeStatus.loading,
    this.summary,
    this.error,
    this.refreshError,
  });

  final HomeStatus status;
  final HomeSummary? summary;

  /// Lỗi lần tải đầu (chưa có số) → thẻ lỗi + "Thử lại".
  final AppException? error;

  /// Lỗi khi tải lại lúc đã có số → giữ số cũ, UI hiện toast.
  final AppException? refreshError;
}
