import 'package:firebase_auth/firebase_auth.dart';

/// Who this install is to the server: an anonymous Firebase user.
abstract class AuthService {
  /// Signs in anonymously on first launch, reuses the current user after that.
  Future<String> ensureSignedIn();
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
}

/// For tests, the debug gallery and when Firebase is unreachable.
class FakeAuthService implements AuthService {
  const FakeAuthService({this.uid = 'fake-uid'});

  final String uid;

  @override
  Future<String> ensureSignedIn() async => uid;
}
