/// Firebase Auth integration placeholders.
/// TODO: Add firebase_core, firebase_auth to pubspec.yaml

class FirebaseAuthService {
  FirebaseAuthService._();
  static final FirebaseAuthService instance = FirebaseAuthService._();

  /// Initialize Firebase in main()
  /// ```dart
  /// await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  /// ```
  Future<void> initialize() async {
    // TODO: await Firebase.initializeApp(...)
  }

  /// Login with email/password.
  /// TODO: FirebaseAuth.instance.signInWithEmailAndPassword(email, password)
  Future<bool> login(String email, String password) async {
    return false;
  }

  /// Register new user.
  /// TODO: FirebaseAuth.instance.createUserWithEmailAndPassword(email, password)
  Future<bool> register(String email, String password) async {
    return false;
  }

  /// Get current user ID for Storage/Firestore paths.
  /// TODO: FirebaseAuth.instance.currentUser?.uid
  String? get currentUserId => null;

  /// Sign out.
  /// TODO: FirebaseAuth.instance.signOut()
  Future<void> signOut() async {}

  /// Verify session before unlocking vault.
  /// TODO: Check FirebaseAuth.instance.currentUser != null
  Future<bool> verifySession() async => false;
}
