import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/models/user_profile_model.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<UserProfileModel?> getUserProfile(String uid);
  Future<UserProfileModel> signInWithEmail(String email, String password);
  Future<UserProfileModel> signUpWithEmail(String displayName, String email, String password);
  Future<UserProfileModel?> signInWithGoogle();
  Future<UserProfileModel> signInWithMicrosoft();
  Future<void> sendPasswordReset(String email);
  Future<bool> isUsernameAvailable(String username);
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String username,
    String? bio,
    String? photoUrl,
  });
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserProfileModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    final baseProfile = UserProfileModel.fromMap(doc.data()!, doc.id);

    // Spark Architecture: Derive verified counters and reputation from immutable Firestore records
    try {
      final helpfulSnap = await _firestore
          .collection('answers')
          .where('authorUid', isEqualTo: uid)
          .where('isHelpful', isEqualTo: true)
          .count()
          .get();

      final answersCountSnap = await _firestore
          .collection('answers')
          .where('authorUid', isEqualTo: uid)
          .count()
          .get();

      final questionsCountSnap = await _firestore
          .collection('questions')
          .where('authorUid', isEqualTo: uid)
          .count()
          .get();

      final followersSnap = await _firestore
          .collection('follows')
          .where('followingUid', isEqualTo: uid)
          .count()
          .get();

      final verifiedHelpful = helpfulSnap.count ?? 0;
      final verifiedAnswers = answersCountSnap.count ?? 0;
      final verifiedQuestions = questionsCountSnap.count ?? 0;
      final verifiedFollowers = followersSnap.count ?? 0;

      // Deterministic verifiable reputation: 15 pts per helpful solution + 5 pts per answer + 2 pts per question
      final derivedReputation = (verifiedHelpful * 15) + (verifiedAnswers * 5) + (verifiedQuestions * 2);

      return baseProfile.copyWith(
        reputation: derivedReputation,
        questionCount: verifiedQuestions,
        answerCount: verifiedAnswers,
        followersCount: verifiedFollowers,
      );
    } catch (_) {
      return baseProfile;
    }
  }

  @override
  Future<UserProfileModel> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      final profile = await getUserProfile(user.uid);
      if (profile != null) return profile;

      return _createInitialProfile(user, user.displayName ?? email.split('@')[0]);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(code: 'sign-in-failed', message: e.toString());
    }
  }

  @override
  Future<UserProfileModel> signUpWithEmail(String displayName, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(displayName.trim());
      return _createInitialProfile(user, displayName.trim());
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(code: 'sign-up-failed', message: e.toString());
    }
  }

  @override
  Future<UserProfileModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled selection
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      final existing = await getUserProfile(user.uid);
      if (existing != null) return existing;

      return _createInitialProfile(user, user.displayName ?? googleUser.displayName ?? 'Google User');
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(code: 'google-sign-in-failed', message: e.toString());
    }
  }

  @override
  Future<UserProfileModel> signInWithMicrosoft() async {
    try {
      final provider = OAuthProvider('microsoft.com');
      provider.addScope('User.Read');
      final userCredential = await _auth.signInWithProvider(provider);
      final user = userCredential.user!;
      final existing = await getUserProfile(user.uid);
      if (existing != null) return existing;

      return _createInitialProfile(user, user.displayName ?? 'Microsoft User');
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(code: 'microsoft-sign-in-failed', message: e.toString());
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final clean = username.trim().toLowerCase();
    if (clean.length < 3 || clean.length > 30) return false;
    final doc = await _firestore.collection('usernames').doc(clean).get();
    return !doc.exists;
  }

  Future<UserProfileModel> _createInitialProfile(User user, String displayName) async {
    final rawUsername = displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    String candidateUsername = rawUsername.isEmpty ? 'user_${user.uid.substring(0, 5)}' : rawUsername;
    if (candidateUsername.length < 3) candidateUsername = '${candidateUsername}123';
    if (candidateUsername.length > 30) candidateUsername = candidateUsername.substring(0, 30);

    // Reserve username document
    try {
      await _firestore.collection('usernames').doc(candidateUsername).set({
        'uid': user.uid,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // If collided, add random suffix
      candidateUsername = 'user_${user.uid.substring(0, 8)}';
      await _firestore.collection('usernames').doc(candidateUsername).set({
        'uid': user.uid,
        'createdAt': DateTime.now().toIso8601String(),
      }).catchError((_) {});
    }

    final profile = UserProfileModel(
      id: user.uid,
      displayName: displayName,
      username: candidateUsername,
      email: user.email,
      photoUrl: user.photoURL,
      reputation: 0,
      questionCount: 0,
      answerCount: 0,
      followersCount: 0,
      followingCount: 0,
      role: 'member',
      status: 'active',
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(profile.toMap());
    return profile;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String username,
    String? bio,
    String? photoUrl,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    // Validate uniqueness if username changed
    final existingUserDoc = await _firestore.collection('users').doc(uid).get();
    final currentUsername = existingUserDoc.data()?['username'] as String?;

    if (currentUsername != cleanUsername) {
      final usernameDoc = await _firestore.collection('usernames').doc(cleanUsername).get();
      if (usernameDoc.exists && usernameDoc.data()?['uid'] != uid) {
        throw Exception('Username "$cleanUsername" is already taken.');
      }
      // Reserve new username
      await _firestore.collection('usernames').doc(cleanUsername).set({
        'uid': uid,
        'createdAt': DateTime.now().toIso8601String(),
      });
      // Delete old username reservation if existed
      if (currentUsername != null && currentUsername.isNotEmpty) {
        await _firestore.collection('usernames').doc(currentUsername).delete().catchError((_) {});
      }
    }

    await _firestore.collection('users').doc(uid).update({
      'displayName': displayName.trim(),
      'username': cleanUsername,
      'bio': bio?.trim(),
      'photoUrl': photoUrl,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut().catchError((_) => null);
    await _auth.signOut();
  }
}

