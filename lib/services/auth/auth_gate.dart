import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:echopay/main.dart';
import 'package:echopay/pages/intro_page.dart';
import 'package:echopay/pages/home_page.dart';
import 'package:echopay/pages/phone_sign_in_page.dart';
import 'package:echopay/services/data/user_data_service.dart';
import 'package:echopay/components/utils.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final ValueNotifier<bool> _isUserDataInitialized = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _newSignIn = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (!_isUserDataInitialized.value) {
            _initializeUserData(snapshot.data!);
            _isUserDataInitialized.value = true;
          }

          if (_newSignIn.value) {
            Utils.hideLoading();
            return HomePage();
          }
          return HomePage();
        } else {
          if (_isUserDataInitialized.value) {
            Future.microtask(() {
              _isUserDataInitialized.value = false;
              _newSignIn.value = false;
            });
          }
        }

        return IntroPage(
          signedIn: false,
          onTapPhone: () {
            print("Phone Sign-in Tapped");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PhoneSignInPage()),
            );
          },
        );
      },
    );
  }

  Future<void> _initializeUserData(User user) async {
    try {
      await UserDataService().initializeUserData(user);
    } catch (e) {
      Utils.hideLoading();
      debugPrint("Error initializing user data: $e");

      if (navigatorKey.currentContext != null) {
        Utils.showSnackBar(
          navigatorKey.currentContext!,
          'Internet not available. Please try again.',
          true,
        );
      }
    }
  }
}
