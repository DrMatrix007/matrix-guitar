import 'package:flutter/material.dart';

import '../practice/practice_session.dart';

class SummaryScreen extends StatelessWidget {
  final String title;
  final SessionSummary summary;
  final String Function(int)? noteName;

  const SummaryScreen({
    super.key,
    required this.title,
    required this.summary,
    this.noteName,
  });

  @override
  Widget build(BuildContext context) {
    final noteName = this.noteName;
    final textTheme = Theme.of(context).textTheme;
    final total = summary.correct + summary.wrong;
    final percent = (summary.accuracy * 100).round();
    final minutes = summary.duration.inMinutes;
    final seconds = (summary.duration.inSeconds % 60).toString().padLeft(
      2,
      '0',
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
            if (noteName != null) ...[
              const SizedBox(height: 16),
              Text('Most troublesome notes', style: textTheme.titleMedium),
              if (summary.troubleNotes.isEmpty) const Text('No wrong notes.'),
              for (final note in summary.troubleNotes)
                Text(
                  '${noteName(note.midi)} - '
                  '${note.wrongCount} wrong',
                ),
            ],
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
