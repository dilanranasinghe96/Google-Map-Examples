import 'package:flutter/material.dart';
import 'package:google_map_preview/custom%20widgets/custom_text.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: Container(
          width: size.width * 0.75,
          height: 40,
          decoration: BoxDecoration(
              color: Colors.purpleAccent.shade100,
              border: Border.all(),
              borderRadius: const BorderRadius.all(Radius.circular(20))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/assets/google_logo.png',
                height: 25,
              ),
              const SizedBox(
                width: 10,
              ),
              CustomText(
                  text: 'Sign up with google',
                  color: Colors.black,
                  fsize: 20,
                  fweight: FontWeight.bold)
            ],
          ),
        ),
      ),
    );
  }
}
