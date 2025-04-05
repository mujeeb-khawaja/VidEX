// lib/screens/result_page.dart
import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final Map<String, dynamic> result;
  const ResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Found'),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              result['movie_name']?.toString() ?? 'N/A',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Genre:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              result['genre']?.toString() ?? 'N/A',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Release Year:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              result['release_year']?.toString() ?? 'N/A',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Storyline:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'N/A',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}