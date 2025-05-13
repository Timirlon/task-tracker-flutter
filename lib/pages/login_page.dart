import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${e.toString()}")),
      );
    }
  }

  Future<void> signUp() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign up failed: ${e.toString()}")),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      // Web version
      try {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(authProvider);
      } catch (e, stack) {
        print("Web Google sign-in failed: $e");
        print(stack);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google sign-in failed: $e")),
        );
      }
    } else {
      // Mobile version
      try {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;

        final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      } catch (e, stack) {
        print("Mobile Google sign-in failed: $e");
        print(stack);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google sign-in failed: $e")),
        );
      }
    }
  }


  Future<void> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) return;

      final OAuthCredential credential =
      FacebookAuthProvider.credential(result.accessToken!.token);

      await _auth.signInWithCredential(credential);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Facebook sign-in failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade100,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Welcome!",
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(hintText: 'Email'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(hintText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: signIn,
                  child: const Text("Login"),
                ),
                TextButton(
                  onPressed: signUp,
                  child: const Text("Don't have an account? Sign up"),
                ),
                const Divider(height: 40),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text("Sign in with Google"),
                  onPressed: signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.facebook),
                  label: const Text("Sign in with Facebook"),
                  onPressed: signInWithFacebook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
