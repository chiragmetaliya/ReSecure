import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validatePassword(String password) {
    // Minimum 8 characters, includes a number, an uppercase letter, a lowercase letter, and a special symbol.
    final passwordRegex = RegExp(
        r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}$');
    return passwordRegex.hasMatch(password);
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (!_validatePassword(password)) {
      setState(() {
        _errorMessage =
            'Password must be at least 8 characters long, include a number, an uppercase letter, a lowercase letter, and a special symbol';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        DatabaseReference userRef =
            FirebaseDatabase.instance.ref().child('users').child(user.uid);
        await userRef.set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
        });

        setState(() {
          _errorMessage = 'Sign up successful';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _signUpWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DatabaseReference userRef =
            FirebaseDatabase.instance.ref().child('users').child(user.uid);
        await userRef.set({
          'firstName': user.displayName?.split(' ')[0] ?? '',
          'lastName': (user.displayName?.split(' ').length ?? 0) > 1
              ? user.displayName?.split(' ')[1]
              : '',
          'email': user.email,
        });

        setState(() {
          _errorMessage = 'Google sign-in successful';
        });
      }
    } catch (e) {
      print("Dbg error: $e");
      setState(() {
        _errorMessage = 'Error during Google sign-in: $e';
      });
    }
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8.0),
                Image.asset(
                  'assets/images/app_logo_png.png',
                  width: 170,
                  height: 177,
                ),
                const Text(
                  'Sign Up',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20.0),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "Email",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.email), // Add email icon here
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    hintText: "First Name",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon:
                        const Icon(Icons.person), // Add person icon here
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    hintText: "Last Name",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon:
                        const Icon(Icons.person), // Add person icon here
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'New Password',
                    prefixIcon: const Icon(Icons.lock), // Add lock icon here
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
                    ), // Add eye icon here
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock), // Add lock icon here
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ), // Add eye icon here
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  obscureText: !_isConfirmPasswordVisible,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20.0),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 9),
                  ),
                ElevatedButton(
                  onPressed: _signUp,
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
                    'Sign Up',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'or',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8.0),
                IconButton(
                  icon: Image.asset('assets/images/devicon_google.png'),
                  iconSize: 40,
                  onPressed: _signUpWithGoogle,
                ),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
