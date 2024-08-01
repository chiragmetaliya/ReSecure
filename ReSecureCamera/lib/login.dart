import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:resecure_camera/forgot_password.dart';
import 'package:resecure_camera/home_screen.dart';
import 'package:resecure_camera/signup.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final String email = _emailController.text;
    final String password = _passwordController.text;

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Login successful: ${userCredential.user?.email}');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      // Navigate to your main app screen here
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  void _forgotPassword() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
    // );
    print('Forgot Password clicked');
  }

  void _signUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpPage()),
    );
    print('Sign Up clicked');
  }

  Future<void> _loginWithGoogle() async {
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
      print("Google sign-in successful: ${userCredential.user?.displayName}");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      // Navigate to your main app screen here
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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
                const SizedBox(height: 16.0),
                Image.asset(
                  'assets/images/app_logo_png.png',
                  width: 190,
                  height: 197,
                ),
                const Text(
                  'Welcome to ReSecure Camera',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18.0),
                const Text(
                  'Login',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 8),
                  ),
                const SizedBox(height: 8.0),
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
                const SizedBox(height: 16.0),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Password',
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF89AAFF),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDAD8D8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 100, vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          15.0), // Adjust this value to reduce curvature
                    ),
                  ),
                  child: const Text(
                    'Login',
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
                  onPressed: _loginWithGoogle,
                ),
                const SizedBox(height: 8.0),
                TextButton(
                  onPressed: _signUp,
                  child: const Text(
                    'New to ReSecure? Sign up here.',
                    style: TextStyle(
                      color: Color(0xFF89AAFF),
                      fontSize: 14,
                    ),
                  ),
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
