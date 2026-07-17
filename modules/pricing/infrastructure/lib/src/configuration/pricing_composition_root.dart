import 'package:get_it/get_it.dart';

abstract final class PricingCompositionRoot {
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
