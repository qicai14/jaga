import 'dart:convert';

/// Server to the protected user's app: `contracts/voice-token.schema.json`. A credential: never logged.
class VoiceToken {
  const VoiceToken({required this.token, required this.expiresAt});

  factory VoiceToken.fromJson(Map<String, dynamic> json) => VoiceToken(
    token: json['token'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );

  factory VoiceToken.parse(String raw) =>
      VoiceToken.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  /// Passed to twilio_voice as it is; the app never reads inside it.
  final String token;
  final DateTime expiresAt;
}
