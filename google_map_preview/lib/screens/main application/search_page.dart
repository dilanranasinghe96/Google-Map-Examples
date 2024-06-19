import 'package:flutter/material.dart';

import '../../custom widgets/custom_text.dart';

class SearchPage extends StatelessWidget {
  final TextEditingController _searchController = TextEditingController();

  SearchPage({super.key, required TextEditingController searchController});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      appBar: AppBar(
        backgroundColor: Colors.amber.shade300,
        title: CustomText(
            text: 'Search Location',
            color: Colors.black,
            fsize: 25,
            fweight: FontWeight.bold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: size.height * 0.1,
            ),
            TextField(
              textAlign: TextAlign.center,
              controller: _searchController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                hintText: 'Search location',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.pop(context, _searchController.text);
                  },
                ),
                filled: true,
                fillColor: Colors.amber.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _searchController.text);
                },
                style: const ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(Colors.amber)),
                child: const Text(
                  'Search',
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
