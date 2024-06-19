import 'package:flutter/material.dart';

import '../../custom widgets/custom_text.dart';

class DirectionsPage extends StatelessWidget {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  DirectionsPage(
      {super.key,
      required TextEditingController startController,
      required TextEditingController endController});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      appBar: AppBar(
        backgroundColor: Colors.amber.shade300,
        title: CustomText(
            text: 'Get Directions',
            color: Colors.black,
            fsize: 25,
            fweight: FontWeight.bold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: size.height * 0.05,
            ),
            CustomText(
                text: 'FROM:',
                color: Colors.black,
                fsize: 25,
                fweight: FontWeight.bold),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                textAlign: TextAlign.center,
                controller: _startController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                  hintText: 'Start location',
                  filled: true,
                  fillColor: Colors.amber.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            CustomText(
                text: 'TO:',
                color: Colors.black,
                fsize: 25,
                fweight: FontWeight.bold),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                textAlign: TextAlign.center,
                controller: _endController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                  hintText: 'End location',
                  filled: true,
                  fillColor: Colors.amber.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'start': _startController.text,
                    'end': _endController.text,
                  });
                },
                style: const ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(Colors.amber)),
                child: const Text(
                  'Get Directions',
                  style: TextStyle(fontSize: 17, color: Colors.black),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
