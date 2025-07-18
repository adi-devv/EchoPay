import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:echopay/services/data/user_data_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:echopay/services/auth/auth_gate.dart';
import 'package:echopay/services/data/creator_service.dart';
import 'package:echopay/components/utils.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String? _creatorId;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> initializeCreatorId() async {
    _creatorId ??= await CreatorService().getCreatorID();
  }

  Future<bool> getStatus() async {
    if (_creatorId == null) {
      await initializeCreatorId();
    }
    final currentUserUid = currentUser?.uid;
    return currentUserUid.toString() == _creatorId;
  }

  bool _isSigningIn = false;

  Future<void> signInWithGoogle(BuildContext context) async {
    if (_isSigningIn) return;
    _isSigningIn = true;

    if (!await hasInternet()) {
      Utils.showSnackBar(context, 'Your internet is on a coffee break!');
      _isSigningIn = false;
      return;
    }
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
      if (gUser == null) {
        print('Google sign-in was aborted.');
        _isSigningIn = false;
        return;
      }
      Utils.showLoading(context, offset: 70);

      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      if (!await hasInternet()) {
        Utils.showSnackBar(context, 'Your internet is on a coffee break!');
        _isSigningIn = false;
        return;
      }

      await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'network-request-failed':
          Utils.showSnackBar(context, 'Your internet is on a coffee break!');
          break;
        default:
          Utils.showSnackBar(context, 'Sign-in failed. Try again.');
      }
      debugPrint("FirebaseAuthException: $e");
    } catch (e) {
      if (e.toString().contains('ApiException: 7')) {
        Utils.showSnackBar(context, 'Your internet is on a coffee break!');
      } else {
        Utils.showSnackBar(context, "Sign-in failed. Try again.");
      }
      debugPrint("Google Sign-In failed: $e");
    } finally {
      Utils.hideLoading();
      _isSigningIn = false;
    }
  }

  Future<bool> hasInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> signOut(BuildContext context) async {
    try {
      Utils.showLoading(context, offset: 70);

      UserDataService().signOut();
      await _firebaseAuth.signOut();
      // await _googleSignIn.signOut();
      Utils.hideLoading();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );

      }
    } catch (e) {
      print("Error during sign out: $e");
    }
  }
}
