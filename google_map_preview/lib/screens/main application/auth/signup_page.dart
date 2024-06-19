import 'package:flutter/material.dart';
import 'package:google_map_preview/custom%20widgets/custom_text.dart';
import 'package:google_map_preview/providers/signup_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

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
      
      backgroundColor: Colors.amber.shade300,
      body: Center(
        
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: size.height * 0.1,
            ),
            CustomText(
                text: 'WELCOME...',
                color: Colors.black,
                fsize: 40,
                fweight: FontWeight.bold),
            SizedBox(
              height: size.height * 0.25,
            ),
            LottieBuilder.asset(
              'lib/assets/login_logo.json',
              height: 150,
            ),
            SizedBox(
              height: size.height * 0.1,
            ),
            Container(
              width: size.width * 0.75,
              height: 40,
              decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: const BorderRadius.all(Radius.circular(20))),
              child: ElevatedButton(
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStatePropertyAll(Colors.purpleAccent.shade100)),
                onPressed: () {
                  Provider.of<SignInProvider>(context, listen: false)
                      .signInWithGoogle(context);
                },
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
          ],
        ),
      ),
    );
  }
}
