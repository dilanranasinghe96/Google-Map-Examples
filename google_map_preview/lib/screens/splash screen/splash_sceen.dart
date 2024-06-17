import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_map_preview/screens/sample%20screens/drawing_routes.dart';
import 'package:google_map_preview/screens/sample%20screens/map_preview.dart';
import 'package:google_map_preview/screens/sample%20screens/on_tap_marker.dart';
import 'package:google_map_preview/screens/sample%20screens/show_locations.dart';
import 'package:lottie/lottie.dart';

import '../main application/main_map_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MapPage(),
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      // backgroundColor: Colors.white.withOpacity(0.7),
      body: Center(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: size.height * 0.4,
            ),
            const Icon(
              Icons.gps_fixed_rounded,
              size: 80,
              color: Colors.blue,
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Location',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
            ),
            SizedBox(
              height: size.height * 0.2,
            ),
            SizedBox(
                width: size.width * 0.5,
                height: size.height * 0.2,
                child: LottieBuilder.asset('lib/assets/animation.json'))
          ],
        ),
      ),
    );
  }
}