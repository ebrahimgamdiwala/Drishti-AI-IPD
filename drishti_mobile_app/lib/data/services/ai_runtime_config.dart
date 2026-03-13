/// Runtime configuration for optional cloud speech integrations.
library;

class AIRuntimeConfig {
  AIRuntimeConfig._();

  static const String googleCloudSttAccessToken = String.fromEnvironment(
    'GOOGLE_CLOUD_STT_ACCESS_TOKEN',
    defaultValue: '',
  );

  static const String googleCloudSttProjectId = String.fromEnvironment(
    'GOOGLE_CLOUD_STT_PROJECT_ID',
    defaultValue: '',
  );

  static const String defaultSpeechLanguage = String.fromEnvironment(
    'GOOGLE_CLOUD_STT_LANGUAGE',
    defaultValue: 'en-US',
  );

  static bool get hasGoogleCloudSttAccessToken =>
      googleCloudSttAccessToken.trim().isNotEmpty;
}
