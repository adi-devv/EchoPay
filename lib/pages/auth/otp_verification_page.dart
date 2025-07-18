import 'package:echopay/pages/auth/phone_sign_in_page.dart';
import 'package:echopay/pages/home_page.dart';
import 'package:echopay/services/data/user_data_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  final UserDataService _userDataService = UserDataService();
  final ValueNotifier<bool> _isVerifyingNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _otpController.dispose();
    _isVerifyingNotifier.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _verifyOtp() async {
    _isVerifyingNotifier.value = true;

    try {
      UserCredential? userCredential = await _userDataService.signInWithOtp(
        widget.verificationId,
        _otpController.text.trim(),
      );

      if (userCredential?.user != null) {
        _showMessage("OTP Verified and Signed In Successfully!");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
              (Route<dynamic> route) => false,
        );
      } else {
        _showMessage("Failed to sign in. Please try again.");
      }
    } on FirebaseAuthException catch (e) {
      _showMessage("OTP Verification Failed: ${e.message}");
      print("OTP Verification Failed: ${e.code} - ${e.message}");
    } catch (e) {
      _showMessage("An unexpected error occurred during OTP verification.");
      print("Unexpected error during OTP verification: $e");
    } finally {
      if (mounted) {
        _isVerifyingNotifier.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: const Text("Verify OTP"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Verification code sent to ${widget.phoneNumber}. Enter OTP below:",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "OTP",
                  hintText: "e.g., 123456",
                  labelStyle: const TextStyle(color: Colors.black87),
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.tealAccent.shade700, width: 2),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<bool>(
                valueListenable: _isVerifyingNotifier,
                builder: (context, isVerifying, child) {
                  return isVerifying
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                      foregroundColor: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        "Verify & Sign In",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
