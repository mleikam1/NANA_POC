import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Future<User> ensureSignedIn() async {
    final existingUser = _firebaseAuth.currentUser;
    if (existingUser != null) {
      return existingUser;
    }

    final credential = await _firebaseAuth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('Anonymous sign-in succeeded without returning a user.');
    }
    return user;
  }
}
