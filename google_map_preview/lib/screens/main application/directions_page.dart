import 'package:flutter/material.dart';

class DirectionsPage extends StatelessWidget {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  DirectionsPage({super.key, required TextEditingController startController, required TextEditingController endController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Directions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _startController,
              decoration: InputDecoration(
                hintText: 'Start location',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _endController,
              decoration: InputDecoration(
                hintText: 'End location',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'start': _startController.text,
                  'end': _endController.text,
                });
              },
              child: const Text('Get Directions'),
            ),
          ],
        ),
      ),
    );
  }
}
