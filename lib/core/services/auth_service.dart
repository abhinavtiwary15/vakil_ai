import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/compliance_item_model.dart';
import 'locale_service.dart';

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  try {
    return FirebaseAuth.instance.authStateChanges();
  } catch (e) {
    debugPrint('Firebase Auth state stream failed: $e');
    return Stream.value(null);
  }
});

// Guest mode provider (persisted locally)
final guestModeProvider = StateProvider<bool>((ref) => false);

// Guest name provider (persisted in Hive)
final guestNameProvider = StateProvider<String?>((ref) => null);

// Current user provider
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final isGuest = ref.watch(guestModeProvider);
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;

  if (user != null) {
    return ref.read(authServiceProvider).getUserFromFirestore(user.uid);
  }

  if (isGuest) {
    // Collect guest name from Hive if possible
    String? guestName;
    try {
      final box = await Hive.openBox('settings');
      guestName = box.get('guestName') as String?;
    } catch (_) {}

    return UserModel(
      uid: 'guest_user',
      displayName: guestName ?? 'Guest User',
      language: ref.read(languageProvider),
      aiQuestionsUsed: 0,
      aiQuestionsLimit: 3,
      docGenerationsUsed: 0,
      docGenerationsLimit: 1,
      createdAt: DateTime.now(),
    );
  }

  return null;
});

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref));

class AuthService {
  final Ref _ref;
  
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  AuthService(this._ref);

  String? _verificationId;

  // Phone OTP
  Future<void> sendOTP(
    String phoneNumber, {
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onAutoVerify,
  }) async {
    final auth = _auth;
    if (auth == null) {
      onError('Firebase not initialized');
      return;
    }
    try {
      await auth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          onAutoVerify(credential);
        },
        verificationFailed: (e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<UserCredential?> verifyOTP(String otp) async {
    final auth = _auth;
    if (auth == null || _verificationId == null) return null;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final result = await auth.signInWithCredential(credential);
      await _createOrUpdateUser(result.user!);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    return null; // TODO: Implement Google Sign In
  }

  Future<void> _createOrUpdateUser(User firebaseUser) async {
    final firestore = _firestore;
    if (firestore == null) return;
    
    final docRef = firestore.collection('users').doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final lang = _ref.read(languageProvider);
      final newUser = UserModel(
        uid: firebaseUser.uid,
        phoneNumber: firebaseUser.phoneNumber,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        language: lang,
        createdAt: DateTime.now(),
      );
      await docRef.set(newUser.toMap());
    }
  }

  Future<UserModel?> getUserFromFirestore(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return null;
    
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    final firestore = _firestore;
    if (firestore == null) return;
    
    try {
      await firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<void> saveBusinessProfile(String uid, BusinessProfile profile) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore.collection('users').doc(uid).update({
        'businessProfile': profile.toMap(),
      });
    } catch (e) {
      print('Error saving business profile: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth?.signOut();
    _ref.read(guestModeProvider.notifier).state = false;
  }

  User? get currentUser => _auth?.currentUser;
}
