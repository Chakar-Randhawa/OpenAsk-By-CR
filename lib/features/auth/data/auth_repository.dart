import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/models/user_profile_model.dart';
import '../../../core/utils/reputation_calculator.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<UserProfileModel?> getUserProfile(String uid);
  Future<UserProfileModel> signInWithEmail(String email, String password);
  Future<UserProfileModel> signUpWithEmail(String displayName, String email, String password);
  Future<UserProfileModel?> signInWithGoogle();
  Future<UserProfileModel> signInWithMicrosoft();
  Future<void> sendPasswordReset(String email);
  Future<void> sendEmailVerification();
  Future<void> updatePassword(String currentPassword, String newPassword);
  Future<void> updateEmail(String currentPassword, String newEmail);
  Future<bool> isUsernameAvailable(String username);
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String username,
    String? bio,
    String? photoUrl,
    String? country,
    String? language,
    String? timezone,
    String? website,
    List<String>? interests,
    bool? isPrivate,
  });
  Future<bool> followUser(String followerUid, String targetUid);
  Future<bool> isFollowingUser(String followerUid, String targetUid);
  Future<List<String>> getFollowingUserIds(String uid);
  Future<void> deleteAccount(String uid, String password);
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
          .where('status', isEqualTo: 'active')
          .count()
          .get();

      final questionsCountSnap = await _firestore
          .collection('questions')
          .where('authorUid', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .count()
          .get();

      final followersSnap = await _firestore
          .collection('follows')
          .where('followingUid', isEqualTo: uid)
          .count()
          .get();

      final followingSnap = await _firestore
          .collection('follows')
          .where('followerUid', isEqualTo: uid)
          .count()
          .get();

      final verifiedHelpful = helpfulSnap.count ?? 0;
      final verifiedAnswers = answersCountSnap.count ?? 0;
      final verifiedQuestions = questionsCountSnap.count ?? 0;
      final verifiedFollowers = followersSnap.count ?? 0;
      final verifiedFollowing = followingSnap.count ?? 0;

      final derivedReputation = ReputationCalculator.calculate(
        helpfulAnswersCount: verifiedHelpful,
        totalAnswersCount: verifiedAnswers,
        totalQuestionsCount: verifiedQuestions,
      );

      return baseProfile.copyWith(
        reputation: derivedReputation,
        questionCount: verifiedQuestions,
        answerCount: verifiedAnswers,
        followersCount: verifiedFollowers,
        followingCount: verifiedFollowing,
      );
    } catch (_) {
      return baseProfile;
    }
  }

  @override
  Future<UserProfileModel> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    final profile = await getUserProfile(user.uid);
    if (profile != null) return profile;

    return _createInitialProfile(user, user.displayName ?? email.split('@')[0]);
  }

  @override
  Future<UserProfileModel> signUpWithEmail(String displayName, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(displayName.trim());
    return _createInitialProfile(user, displayName.trim());
  }

  @override
  Future<UserProfileModel?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;
    final existing = await getUserProfile(user.uid);
    if (existing != null) return existing;

    return _createInitialProfile(user, user.displayName ?? googleUser.displayName ?? 'Google Member');
  }

  @override
  Future<UserProfileModel> signInWithMicrosoft() async {
    final provider = OAuthProvider('microsoft.com');
    provider.addScope('User.Read');
    final userCredential = await _auth.signInWithProvider(provider);
    final user = userCredential.user!;
    final existing = await getUserProfile(user.uid);
    if (existing != null) return existing;

    return _createInitialProfile(user, user.displayName ?? 'Microsoft Member');
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
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('No authenticated user.');

    // Re-authenticate first
    final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  @override
  Future<void> updateEmail(String currentPassword, String newEmail) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('No authenticated user.');

    final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(cred);
    await user.verifyBeforeUpdateEmail(newEmail.trim());
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String username,
    String? bio,
    String? photoUrl,
    String? country,
    String? language,
    String? timezone,
    String? website,
    List<String>? interests,
    bool? isPrivate,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final existingUserDoc = await _firestore.collection('users').doc(uid).get();
    final currentUsername = existingUserDoc.data()?['username'] as String?;

    if (currentUsername != cleanUsername) {
      final usernameDoc = await _firestore.collection('usernames').doc(cleanUsername).get();
      if (usernameDoc.exists && usernameDoc.data()?['uid'] != uid) {
        throw Exception('Username "$cleanUsername" is already taken.');
      }
      await _firestore.collection('usernames').doc(cleanUsername).set({
        'uid': uid,
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (currentUsername != null && currentUsername.isNotEmpty) {
        await _firestore.collection('usernames').doc(currentUsername).delete().catchError((_) {});
      }
    }

    final updateData = <String, dynamic>{
      'displayName': displayName.trim(),
      'username': cleanUsername,
      'bio': bio?.trim(),
      'photoUrl': photoUrl,
      'country': country,
      'language': language ?? 'en',
      'timezone': timezone,
      'website': website?.trim(),
      'interests': interests ?? [],
      'isPrivate': isPrivate ?? false,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await _firestore.collection('users').doc(uid).update(updateData);
  }

  @override
  Future<bool> followUser(String followerUid, String targetUid) async {
    final followId = '${followerUid}_$targetUid';
    final followRef = _firestore.collection('follows').doc(followId);
    final snap = await followRef.get();

    if (snap.exists) {
      await followRef.delete();
      return false;
    } else {
      await followRef.set({
        'id': followId,
        'followerUid': followerUid,
        'followingUid': targetUid,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Dispatch follow notification
      try {
        final notifRef = _firestore.collection('notifications').doc();
        await notifRef.set({
          'id': notifRef.id,
          'recipientUid': targetUid,
          'senderUid': followerUid,
          'type': 'follow',
          'title': 'New Follower',
          'body': 'A member started following your contributions.',
          'targetType': 'user',
          'targetId': followerUid,
          'isRead': false,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      return true;
    }
  }

  @override
  Future<bool> isFollowingUser(String followerUid, String targetUid) async {
    final followId = '${followerUid}_$targetUid';
    final snap = await _firestore.collection('follows').doc(followId).get();
    return snap.exists;
  }

  @override
  Future<List<String>> getFollowingUserIds(String uid) async {
    final snap = await _firestore
        .collection('follows')
        .where('followerUid', isEqualTo: uid)
        .limit(100)
        .get();

    return snap.docs.map((d) => d.data()['followingUid'] as String).toList();
  }

  @override
  Future<void> deleteAccount(String uid, String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('No authenticated user.');

    // 1. Re-authenticate
    final cred = EmailAuthProvider.credential(email: user.email!, password: password);
    await user.reauthenticateWithCredential(cred);

    // 2. Anonymize user document (preserves referential integrity while wiping PII)
    final usernameDoc = await _firestore.collection('users').doc(uid).get();
    final currentUsername = usernameDoc.data()?['username'] as String?;
    if (currentUsername != null) {
      await _firestore.collection('usernames').doc(currentUsername).delete().catchError((_) {});
    }

    await _firestore.collection('users').doc(uid).update({
      'displayName': 'Deleted Account',
      'username': 'deleted_${uid.substring(0, 5)}',
      'bio': null,
      'photoUrl': null,
      'email': null,
      'status': 'deleted',
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // 3. Delete Firebase Auth account
    await user.delete();
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut().catchError((_) => null);
    await _auth.signOut();
  }
}
