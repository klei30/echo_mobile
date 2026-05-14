// Stub for non-web platforms
class WebOAuthHandler {
  static Future<Map<String, dynamic>> startOAuthFlow({
    required String authorizationUrl,
    String? clientId,
    required String redirectUri,
    required String scope,
    String? state,
  }) async {
    throw UnsupportedError('OAuth is only supported on web platform');
  }

  static Future<Map<String, dynamic>> exchangeCodeForToken({
    required String tokenUrl,
    String? clientId,
    String? clientSecret,
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    throw UnsupportedError('OAuth is only supported on web platform');
  }

  static Future<Map<String, dynamic>> refreshToken({
    required String tokenUrl,
    String? clientId,
    String? clientSecret,
    required String refreshToken,
  }) async {
    throw UnsupportedError('OAuth is only supported on web platform');
  }
}
