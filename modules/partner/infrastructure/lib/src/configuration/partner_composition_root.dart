import 'package:get_it/get_it.dart';

/// Meetings-aligned composition root: holds the module GetIt container and lifetime scopes.
abstract final class PartnerCompositionRoot {
  static late GetIt _container;

  static void setContainer(GetIt container) {
    _container = container;
  }

  static GetIt get container => _container;

  static Future<T> beginLifetimeScope<T>(
    Future<T> Function(GetIt scope) action, {
    String? scopeName,
  }) async {
    _container.pushNewScope(scopeName: scopeName);
    try {
      return await action(_container);
    } finally {
      await _container.popScope();
    }
  }
}
