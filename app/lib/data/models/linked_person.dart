/// The protected person this co-pilot watches over, from the local link record
/// (written by onboarding). The nickname here wins over the name in a push.
class LinkedPerson {
  const LinkedPerson({required this.name, this.phoneNumber});

  final String name;

  /// Null when the link response did not carry one: the Call button then opens
  /// the dialer empty.
  final String? phoneNumber;
}
