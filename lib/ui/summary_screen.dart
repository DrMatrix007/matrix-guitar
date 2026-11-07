import 'package:flutter/material.dart';

import '../practice/practice_session.dart';
import '../theory/scale.dart';

class SummaryScreen extends StatelessWidget {
  final ScaleDefinition scale;
  final SessionSummary summary;

  const SummaryScreen({super.key, required this.scale, required this.summary});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = summary.correct + summary.wrong;
    final percent = (summary.accuracy * 100).round();
    final minutes = summary.duration.inMinutes;
    final seconds = (summary.duration.inSeconds % 60).toString().padLeft(
      2,
      '0',
    );

    return Scaffold(
      appBar: AppBar(title: Text(scale.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Accuracy', style: textTheme.titleMedium),
            Text(
              '${summary.correct} of $total ($percent%)',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('Time taken', style: textTheme.titleMedium),
            Text('$minutes:$seconds', style: textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text('Most troublesome notes', style: textTheme.titleMedium),
            if (summary.troubleNotes.isEmpty) const Text('No wrong notes.'),
            for (final note in summary.troubleNotes)
              Text(
                '${scale.spelledNote(note.midi)} - '
                '${note.wrongCount} wrong',
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
