/// What the server returns when a protected user is set up (no contract yet:
/// requested from contracts #1).
class Registration {
  const Registration({
    required this.protectedUserId,
    required this.jagaLineNumber,
    required this.pauseToken,
    required this.linkCode,
  });

  factory Registration.fromJson(Map<String, dynamic> json) => Registration(
    protectedUserId: json['protectedUserId'] as String,
    jagaLineNumber: json['jagaLineNumber'] as String,
    pauseToken: json['pauseToken'] as String,
    linkCode: json['linkCode'] as String,
  );

  final String protectedUserId;

  /// The Jaga line, in international format.
  final String jagaLineNumber;
  final String pauseToken;

  /// Six digits.
  final String linkCode;

  /// Dialled once on the protected phone to forward its calls to the Jaga line.
  String get forwardingCode => '*21*${jagaLineNumber.replaceAll(' ', '')}#';

  /// Dialled to read back where calls are forwarded.
  static const checkForwardingCode = '*#21#';

  Map<String, dynamic> toJson() => {
    'protectedUserId': protectedUserId,
    'jagaLineNumber': jagaLineNumber,
    'pauseToken': pauseToken,
    'linkCode': linkCode,
  };
}
