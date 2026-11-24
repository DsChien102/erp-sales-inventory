/// Kết quả đăng xuất: phiên máy luôn được xoá; máy chủ có thể chưa xác nhận.
final class SignOutResult {
  const SignOutResult({
    required this.localCleared,
    required this.remoteSucceeded,
  });

  final bool localCleared;
  final bool remoteSucceeded;
}
