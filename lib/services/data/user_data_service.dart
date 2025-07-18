import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echopay/components/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:echopay/main.dart';

class UserDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserDataService._internal();

  static final UserDataService _instance = UserDataService._internal();

  factory UserDataService() => _instance;

  Map<String, dynamic>? cachedUserData;

  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  Future<void> initializeUserData(User user) async {
    final docRef = _firestore.collection('Users').doc(user.uid);

    try {
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print(navigatorKey.currentContext == null);
        await _createUserDocument(docRef, user);
      } else {
        cachedUserData = docSnapshot.data();
      }
    } catch (e) {
      print("Error initializing user data: $e");
    }
  }

  Future<void> _createUserDocument(DocumentReference docRef, User user) async {
    String userNum = user.phoneNumber ?? user.uid;

    final Map<String, dynamic> initialData = {
      'uid': user.uid,
      'email': user.email,
      'name': user.displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'echoID': '$userNum@echopay',
      'phone': user.phoneNumber,
    };

    cachedUserData = initialData;
    WriteBatch batch = _firestore.batch();
    batch.set(docRef, initialData);

    await batch.commit();
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
      );

    } catch (e) {
      print("Error initiating phone verification: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signInWithOtp(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("Error signing in with OTP: ${e.message}");
      rethrow;
    } catch (e) {
      print("An unexpected error occurred during OTP sign-in: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    cachedUserData?.clear();
  }
}
