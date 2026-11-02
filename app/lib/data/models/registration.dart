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
  /// Empty when the build has no valid Jaga line (unset or not `+` and 8-15
  /// digits, so no `*` or `#` can change the code): never a dead number.
  String get forwardingCode {
    final number = jagaLineNumber.replaceAll(' ', '');
    return _e164.hasMatch(number) ? '*21*$number#' : '';
  }

  static final _e164 = RegExp(r'^\+\d{8,15}$');

  /// Dialled to cancel forwarding; needs no Jaga line.
  static const cancelForwardingCode = '##21#';

  /// Dialled to read back where calls are forwarded.
  static const checkForwardingCode = '*#21#';

  Map<String, dynamic> toJson() => {
    'protectedUserId': protectedUserId,
    'jagaLineNumber': jagaLineNumber,
    'pauseToken': pauseToken,
    'linkCode': linkCode,
  };
}
