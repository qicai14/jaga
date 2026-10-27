import 'package:firebase_auth/firebase_auth.dart';

/// Who this install is to the server: an anonymous Firebase user. The ID token
/// authenticates the server calls that arrive with contracts v1.
abstract class AuthService {
  /// Signs in anonymously on first launch, reuses the current user after that.
  Future<String> ensureSignedIn();

  /// A fresh ID token for the signed-in user, or null when signed out.
  Future<String?> idToken();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService([FirebaseAuth? auth])
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Future<String> ensureSignedIn() async {
    final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user!;
    return user.uid;
  }

  @override
  Future<String?> idToken() async => _auth.currentUser?.getIdToken();
}

/// For tests, the debug gallery and when Firebase is unreachable.
class FakeAuthService implements AuthService {
  const FakeAuthService({this.uid = 'fake-uid'});

  final String uid;

  @override
  Future<String> ensureSignedIn() async => uid;

  @override
  Future<String?> idToken() async => 'fake-id-token';
}
