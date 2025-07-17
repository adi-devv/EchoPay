import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

// Placeholder for OTP verification page.
// This page will now receive the verificationId.
class OtpVerificationPage extends StatelessWidget {
  final String phoneNumber;
  final String verificationId; // New: To pass Firebase's verification ID

  const OtpVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.verificationId, // Required now
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Verification code sent to $phoneNumber. Enter OTP below:",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "OTP",
                  hintText: "e.g., 123456",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (otp) {
                  // TODO: Implement OTP verification logic here
                  // You will use this 'otp' and the 'verificationId'
                  // to sign in with Firebase.
                  // Example:
                  // PhoneAuthCredential credential = PhoneAuthProvider.credential(
                  //   verificationId: verificationId,
                  //   smsCode: otp,
                  // );
                  // FirebaseAuth.instance.signInWithCredential(credential);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // In a real app, you'd trigger the verification here
                  // based on the entered OTP.
                  print("Verify OTP button pressed for $phoneNumber with ID: $verificationId");
                  // For now, just pop to simulate completion
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "Verify & Sign In",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PhoneSignInPage extends StatefulWidget {
  const PhoneSignInPage({super.key});

  @override
  _PhoneSignInPageState createState() => _PhoneSignInPageState();
}

class _PhoneSignInPageState extends State<PhoneSignInPage> {
  final TextEditingController _countryCodeController = TextEditingController(text: '+91'); // Default to +91
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false; // To show loading state on button

  @override
  void dispose() {
    _countryCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Function to show a simple message (instead of alert)
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Firebase Phone Verification Logic
  Future<void> _verifyPhoneNumber() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    // Combine country code and phone number for E.164 format
    String fullPhoneNumber = _countryCodeController.text.trim() + _phoneController.text.trim();

    // Basic validation
    if (!fullPhoneNumber.startsWith('+') || fullPhoneNumber.length < 10) {
      _showMessage("Please enter a valid phone number including country code (e.g., +919876543210).");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // This callback is triggered when an SMS code is automatically retrieved (Android only)
          // or if the phone number is already verified on the device.
          print("Verification completed: ${credential.smsCode}");
          _showMessage("Phone number automatically verified!");
          // You can sign in the user directly here
          // await FirebaseAuth.instance.signInWithCredential(credential);
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage())); // Navigate to home
        },
        verificationFailed: (FirebaseAuthException e) {
          // Handle verification failures (e.g., invalid phone number, quota exceeded)
          print("Verification failed: ${e.message}");
          _showMessage("Verification failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) async {
          // This callback is triggered when the SMS code is sent to the user's phone.
          print("Code sent to $fullPhoneNumber. Verification ID: $verificationId");
          _showMessage("Verification code sent to your phone!");

          // Navigate to the OTP verification page, passing the verificationId
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationPage(
                phoneNumber: fullPhoneNumber,
                verificationId: verificationId, // Pass the ID
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // This callback is triggered when the SMS code auto-retrieval times out.
          print("Auto-retrieval timeout for ID: $verificationId");
          _showMessage("SMS auto-retrieval timed out. Please enter code manually.");
          // You might still want to navigate to OTP page here,
          // as the user will need to manually enter the code.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationPage(
                phoneNumber: fullPhoneNumber,
                verificationId: verificationId,
              ),
            ),
          );
        },
        timeout: const Duration(seconds: 60), // Optional: set a timeout for SMS delivery
      );
    } catch (e) {
      print("Error during phone verification: $e");
      _showMessage("An unexpected error occurred. Please try again.");
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
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
                // Country Code Input
                SizedBox(
                  width: 80, // Adjust width as needed
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
                      FilteringTextInputFormatter.allow(RegExp(r'^\+?[0-9]*')), // Allow + and digits
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Phone Number Input
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
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
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
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _verifyPhoneNumber,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Colors.white,
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
