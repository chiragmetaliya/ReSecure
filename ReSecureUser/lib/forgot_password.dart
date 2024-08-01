import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import 'package:resecure_user/email_service.dart'; // Updated import

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _codeControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _errorMessage;
  bool _isCodeSectionVisible = false;
  bool _isPasswordSectionVisible = false;
  bool _isPasswordVisible = false;
  String? _verificationCode;

  final EmailService _emailService = EmailService();

  Future<void> _submitEmail() async {
    final email = _emailController.text;

    // Check if the email exists in Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (userDoc.docs.isEmpty) {
      // Show error message if email is not found
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Email not found'),
      ));
      return;
    }

    // Generate a random 6-digit OTP
    _verificationCode = (Random().nextInt(900000) + 100000).toString();

    // Send OTP email
    try {
      await _emailService.sendEmail(
        email,
        'Password Reset Code',
        'Your password reset code is $_verificationCode',
      );

      setState(() {
        _isCodeSectionVisible = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('OTP sent to $email'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error sending OTP: $e'),
      ));
    }
  }

  void _submitCode() {
    final enteredCode =
        _codeControllers.map((controller) => controller.text).join();

    if (enteredCode == _verificationCode) {
      setState(() {
        _isPasswordSectionVisible = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invalid OTP'),
      ));
    }
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final email = _emailController.text;

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Passwords do not match'),
      ));
      return;
    }

    if (!_validatePassword(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Password must be at least 8 characters, include an uppercase letter, a lowercase letter, a number, and a special character.'),
      ));
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Email not found'),
        ));
        return;
      }

      final oldPassword = userDoc.docs.first.get('password');

      if (oldPassword == newPassword) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('New password cannot be the same as the old password'),
        ));
        return;
      }

      // Update password in Firebase Auth
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && user.email == email) {
        await user.updatePassword(newPassword);
      } else {
        // If user is not logged in, sign in with email link to update password
        final authCredential =
            EmailAuthProvider.credential(email: email, password: oldPassword);
        user =
            (await FirebaseAuth.instance.signInWithCredential(authCredential))
                .user;
        if (user != null) {
          await user.updatePassword(newPassword);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password changed successfully'),
      ));

      // Optionally navigate to the login page or another page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error changing password: $e'),
      ));
    }
  }

  bool _validatePassword(String password) {
    final regex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return regex.hasMatch(password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 16.0),
                Image.asset(
                  'assets/images/app_logo_png.png',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Forgot Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 9),
                  ),
                const SizedBox(height: 16.0),
                if (!_isCodeSectionVisible && !_isPasswordSectionVisible) ...[
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: "Registered Email",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _submitEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDAD8D8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 100, vertical: 15),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
                if (_isCodeSectionVisible) ...[
                  const SizedBox(height: 16.0),
                  const Divider(color: Colors.white),
                  const SizedBox(height: 16.0),
                  const Text(
                    'We have sent you a code in email. Enter that code below.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 40,
                        child: TextField(
                          controller: _codeControllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            counterText: "",
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              if (index < 5) {
                                _focusNodes[index].unfocus();
                                FocusScope.of(context)
                                    .requestFocus(_focusNodes[index + 1]);
                              } else {
                                _focusNodes[index].unfocus();
                              }
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _submitCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDAD8D8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 100, vertical: 15),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
                if (_isPasswordSectionVisible) ...[
                  const SizedBox(height: 16.0),
                  const Divider(color: Colors.white),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Set New Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDAD8D8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 60, vertical: 15),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: const Text(
                      'Change Password',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
