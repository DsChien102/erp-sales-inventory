import 'package:erp/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnvironment', () {
    test('fromString maps known values', () {
      expect(AppEnvironment.fromString('development'), AppEnvironment.development);
      expect(AppEnvironment.fromString('dev'), AppEnvironment.development);
      expect(AppEnvironment.fromString('staging'), AppEnvironment.staging);
      expect(AppEnvironment.fromString('production'), AppEnvironment.production);
      expect(AppEnvironment.fromString('prod'), AppEnvironment.production);
    });

    test('fromString defaults unknown to development', () {
      expect(AppEnvironment.fromString(''), AppEnvironment.development);
      expect(AppEnvironment.fromString('unknown'), AppEnvironment.development);
    });

    test('display names and banners', () {
      expect(AppEnvironment.development.displayName, 'Mosaic Retail Dev');
      expect(AppEnvironment.staging.displayName, 'Mosaic Retail Staging');
      expect(AppEnvironment.production.displayName, 'Mosaic Retail');

      expect(AppEnvironment.development.bannerLabel, 'DEV');
      expect(AppEnvironment.staging.bannerLabel, 'STAGING');
      expect(AppEnvironment.production.bannerLabel, isNull);
    });

    test('isDevelopment is false for staging and production', () {
      expect(AppEnvironment.staging.isDevelopment, isFalse);
      expect(AppEnvironment.production.isDevelopment, isFalse);
      expect(AppEnvironment.development.isDevelopment, isTrue);
    });
  });
}
