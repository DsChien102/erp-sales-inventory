enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromString(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      case 'development':
      case 'dev':
      default:
        return AppEnvironment.development;
    }
  }

  String get value => switch (this) {
        AppEnvironment.development => 'development',
        AppEnvironment.staging => 'staging',
        AppEnvironment.production => 'production',
      };

  String get displayName => switch (this) {
        AppEnvironment.development => 'Mosaic Retail Dev',
        AppEnvironment.staging => 'Mosaic Retail Staging',
        AppEnvironment.production => 'Mosaic Retail',
      };

  String? get bannerLabel => switch (this) {
        AppEnvironment.development => 'DEV',
        AppEnvironment.staging => 'STAGING',
        AppEnvironment.production => null,
      };

  bool get isDevelopment => this == AppEnvironment.development;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProduction => this == AppEnvironment.production;
}
