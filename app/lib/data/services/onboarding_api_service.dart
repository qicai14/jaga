import '../models/linked_person.dart';
import '../models/registration.dart';

/// The server is unreachable.
class OnboardingNetworkException implements Exception {
  const OnboardingNetworkException();
}

enum JoinError { invalid, expired, full }

/// The link code was refused.
class JoinException implements Exception {
  const JoinException(this.error);

  final JoinError error;
}

/// Setup calls to the server. No contract exists yet (requested from
/// contracts #1), so only [FakeOnboardingApiService] implements this.
abstract class OnboardingApiService {
  Future<Registration> register({
    required String region,
    required String commandLanguage,
    required String personName,
  });

  /// Names of the family co-pilots who have joined.
  Future<List<String>> copilots(String protectedUserId);

  /// The protected user's name for a valid link code; else a [JoinException].
  Future<String> checkLinkCode(String code);

  /// Joins as a co-pilot. [LinkedPerson.phoneNumber] feeds the alert's Call button.
  Future<LinkedPerson> join({
    required String linkCode,
    required String copilotName,
  });
}

const fakeLinkCode = '482913';
const fakeRegistration = Registration(
  protectedUserId: 'pu-1',
  jagaLineNumber: '+15550100199',
  pauseToken: 'JAGA-7Q4M-2KXP-9D3F',
  linkCode: fakeLinkCode,
);
const fakeProtectedUserName = 'Aminah';
const fakeProtectedUserPhone = '+60123456789';

/// Fixtures: link code `000000` is full, `111111` expired, [fakeLinkCode]
/// valid, anything else wrong.
class FakeOnboardingApiService implements OnboardingApiService {
  /// Every call throws [OnboardingNetworkException], to test failures.
  bool offline = false;

  /// [register] waits for this first, to show the busy state.
  Future<void>? hold;

  /// What [copilots] returns.
  List<String> joined = const [];

  void _reach() {
    if (offline) throw const OnboardingNetworkException();
  }

  @override
  Future<Registration> register({
    required String region,
    required String commandLanguage,
    required String personName,
  }) async {
    _reach();
    await hold;
    return fakeRegistration;
  }

  @override
  Future<List<String>> copilots(String protectedUserId) async {
    _reach();
    return joined;
  }

  @override
  Future<String> checkLinkCode(String code) async {
    _reach();
    return switch (code) {
      fakeLinkCode => fakeProtectedUserName,
      '000000' => throw const JoinException(JoinError.full),
      '111111' => throw const JoinException(JoinError.expired),
      _ => throw const JoinException(JoinError.invalid),
    };
  }

  @override
  Future<LinkedPerson> join({
    required String linkCode,
    required String copilotName,
  }) async {
    final name = await checkLinkCode(linkCode);
    return LinkedPerson(name: name, phoneNumber: fakeProtectedUserPhone);
  }
}
