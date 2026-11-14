import 'package:flutter/material.dart';

import '../theory/harmony.dart';
import 'theory_visualization.dart';
import 'fretboard_key_selector.dart';

/// An ungraded space to connect chord construction with harmonic function.
class ProgressionExplorer extends StatefulWidget {
  const ProgressionExplorer({super.key});

  @override
  State<ProgressionExplorer> createState() => _ProgressionExplorerState();
}

class _ProgressionExplorerState extends State<ProgressionExplorer> {
  int _key = 0;
  int _progression = 0;
  bool _guideTones = false;

  @override
  Widget build(BuildContext context) {
    final progression = harmonyProgressions[_progression];
    final chords = progression.chords(_key, (minFret: 3, maxFret: 7));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Understand the progression',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Text(
          'A chord is a collection of notes; a progression gives those notes a direction. Explore home, departure, tension and resolution before testing yourself.',
        ),
        const SizedBox(height: 12),
        FretboardKeySelector(
          root: _key,
          onChanged: (value) => setState(() => _key = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _progression,
          decoration: const InputDecoration(labelText: 'Explore progression'),
          items: [
            for (final (index, p) in harmonyProgressions.indexed)
              DropdownMenuItem(value: index, child: Text(p.name)),
          ],
          onChanged: (value) => setState(() => _progression = value!),
        ),
        const SizedBox(height: 16),
        const Text(
          'Follow the harmony →',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chord in chords)
              Chip(label: Text('${chord.function.roman} · ${chord.name}')),
          ],
        ),
        const Text(
          'Roman numerals count from the key home note. Chord formulas count from each chord’s own root. The same chord can have different roles in different keys.',
        ),
        for (final chord in chords)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${chord.function.roman} · ${chord.name}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${chord.function.quality.formula} = ${chord.noteNames.join('–')}',
                  ),
                  Text(chord.function.explanation),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Why the changes connect',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (var i = 1; i < chords.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(_connection(chords[i - 1], chords[i])),
          ),
        const Text(
          'Common tones can stay in place while other voices move. Small movements often make a change sound connected; rhythm, melody and voicing also shape how much tension you hear.',
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Trace guide tones'),
          subtitle: const Text(
            'Compare a line of thirds and sevenths across the chords.',
          ),
          value: _guideTones,
          onChanged: (value) => setState(() => _guideTones = value),
        ),
        TheoryVisualization(
          key: ValueKey((_key, _progression, _guideTones)),
          chords: chords,
          guideTones: _guideTones,
        ),
        if (_guideTones)
          for (final target in harmonyTargets(chords, guideTones: true))
            Text(
              '${target.chord.name}: ${target.chord.toneName(target.tone)} · ${target.explanation}',
            ),
        const Text(
          'Try it: play each chord slowly for four beats, then sing one shared or nearby note through the change. Stop on V, then play I and compare the feeling of arrival. These diagrams show individual pitches; use chord shapes for strumming.',
        ),
        const Divider(height: 32),
      ],
    );
  }

  String _connection(HarmonyChord from, HarmonyChord to) {
    final shared = [
      for (final tone in from.tones)
        if (to.tones.any((t) => to.pitchClass(t) == from.pitchClass(tone)))
          from.toneName(tone),
    ];
    return '${from.name} → ${to.name}: ${shared.isEmpty ? 'no common chord tones; look for nearby notes in the visualization.' : 'shared tones ${shared.join(', ')} can be held while the other notes move.'}';
  }
}
