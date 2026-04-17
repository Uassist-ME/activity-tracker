class Env {
  static const apiUrl = String.fromEnvironment('API_URL');
  static const apiKey = String.fromEnvironment('API_KEY');
  static const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  static bool get isProd => environment == 'prod';
  static bool get isStaging => environment == 'staging';
  static bool get isDev => environment == 'dev';
}
