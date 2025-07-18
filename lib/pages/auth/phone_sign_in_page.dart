import 'package:echopay/pages/auth/otp_verification_page.dart';
import 'package:echopay/services/data/user_data_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneSignInPage extends StatefulWidget {
  const PhoneSignInPage({super.key});

  @override
  _PhoneSignInPageState createState() => _PhoneSignInPageState();
}

class _PhoneSignInPageState extends State<PhoneSignInPage> {
  final TextEditingController _countryCodeController = TextEditingController(text: '+91');
  final TextEditingController _phoneController = TextEditingController();
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  final UserDataService _userDataService = UserDataService();

  @override
  void dispose() {
    _countryCodeController.dispose();
    _phoneController.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _verifyPhoneNumber() async {
    _isLoadingNotifier.value = true;

    String fullPhoneNumber = _countryCodeController.text.trim() + _phoneController.text.trim();

    if (!fullPhoneNumber.startsWith('+') || fullPhoneNumber.length < 10) {
      _showMessage("Please enter a valid phone number including country code (e.g., +919876543210).");
      _isLoadingNotifier.value = false;
      return;
    }

    try {
      await _userDataService.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print("Verification completed: ${credential.smsCode}");
          _showMessage("Phone number automatically verified!");
          if (mounted) {
            _isLoadingNotifier.value = false;
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print("Verification failed: ${e.message}");
          _showMessage("Verification failed: ${e.message}");
          if (mounted) {
            _isLoadingNotifier.value = false;
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          print("Code sent to $fullPhoneNumber. Verification ID: $verificationId");
          _showMessage("Verification code sent to your phone!");

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationPage(
                phoneNumber: fullPhoneNumber,
                verificationId: verificationId,
              ),
            ),
          );
          if (mounted) {
            _isLoadingNotifier.value = false;
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print("Auto-retrieval timeout for ID: $verificationId");
          _showMessage("SMS auto-retrieval timed out. Please enter code manually.");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationPage(
                phoneNumber: fullPhoneNumber,
                verificationId: verificationId,
              ),
            ),
          );
          if (mounted) {
            _isLoadingNotifier.value = false;
          }
        },
      );
    } catch (e) {
      print("Error during phone verification: $e");
      _showMessage("An unexpected error occurred. Please try again.");
    } finally {
      if (mounted) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: AppBar(
        title: const Text("Sign in with Phone"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Enter your phone number to continue",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _countryCodeController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Code",
                      labelStyle: const TextStyle(color: Colors.black87),
                      hintStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\+?[0-9]*')),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      hintText: "e.g., 9876543210",
                      labelStyle: const TextStyle(color: Colors.black87),
                      hintStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.tealAccent.shade700, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyPhoneNumber,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text(
                "Send Verification Code",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
