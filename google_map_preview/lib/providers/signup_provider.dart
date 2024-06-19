import 'package:flutter/material.dart';
import 'package:google_map_preview/controllers/auth_controlller.dart';

class SignInProvider extends ChangeNotifier {
  AuthController authController = AuthController();

//Sign In user

  Future<void> signInWithGoogle(BuildContext context) async {
    await authController.signInWithGoogle(context);
  }
}
