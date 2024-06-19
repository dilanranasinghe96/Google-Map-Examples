import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_map_preview/screens/main%20application/auth/signup_page.dart';
import 'package:google_map_preview/screens/main%20application/main_map_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class AuthController {
  // Check auth state
  static Future<void> checkAuthState(BuildContext context) async {
    Future.delayed(const Duration(seconds: 5), () {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SignUpPage(),
            ),
          );
          Logger().i('User is currently signed out!');
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MapPage(user: user),
            ),
          );
          Logger().i('User is signed in!');
        }
      });
    });
  }

  // Sign out user
  static Future<void> signOutUser(BuildContext context) async {
    Future.delayed(const Duration(seconds: 4), () async {
      try {
        await FirebaseAuth.instance.signOut();
        Logger().i("User logged out");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SignUpPage(),
          ),
        );
      } catch (e) {
        Logger().e("Error signing out: $e");
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Sign-Out Failed'),
              content: Text('Error: $e'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    });
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return null; // User canceled sign-in
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Check if sign-in was successful
      if (userCredential.user != null) {
        Logger().i("Sign-in with Google successful.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MapPage(user: userCredential.user!),
          ),
        );
      }

      return userCredential;
    } catch (e) {
      Logger().e("Error signing in with Google: $e");
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Sign-In Failed'),
            content: Text('Error: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
    return null;
  }
}
