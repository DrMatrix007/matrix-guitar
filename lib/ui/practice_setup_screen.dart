import 'package:flutter/material.dart';

import '../audio/audio_source.dart';
import '../practice/practice_options.dart';
import '../theory/scale.dart';
import 'practice_screen.dart';

const _defaults = PracticeOptions();

class PracticeSetupScreen extends StatefulWidget {
  final ScaleDefinition scale;
  final AudioSource Function(List<ScalePosition>) audioSourceFactory;

  const PracticeSetupScreen({
    super.key,
    required this.scale,
    required this.audioSourceFactory,
  });

  @override
  State<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends State<PracticeSetupScreen> {
  PracticeDirection _direction = _defaults.direction;
  NoteOrder _order = _defaults.order;
  int _repeats = _defaults.repeats;
  HintLevel _hints = _defaults.hints;

  void _start() {
    final options = PracticeOptions(
      direction: _direction,
      order: _order,
      repeats: _repeats,
      hints: _hints,
    );
    final sequence = generateSequence(widget.scale.positions, options);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeScreen(
          scale: widget.scale,
          sequence: sequence,
          hints: options.hints,
          audioSourceFactory: widget.audioSourceFactory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.scale.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ChipGroup<PracticeDirection>(
              label: 'Direction',
              labels: const {
                PracticeDirection.ascending: 'Ascending',
                PracticeDirection.descending: 'Descending',
                PracticeDirection.both: 'Both',
              },
              selected: _direction,
              onSelected: _order == NoteOrder.random
                  ? null
                  : (value) => setState(() => _direction = value),
            ),
            _ChipGroup(
              label: 'Note order',
              labels: const {
                NoteOrder.straight: 'Straight',
                NoteOrder.thirds: 'Thirds',
                NoteOrder.groupsOf3: 'Groups of 3',
                NoteOrder.groupsOf4: 'Groups of 4',
                NoteOrder.random: 'Random',
              },
              selected: _order,
              onSelected: (value) => setState(() {
                _order = value;
                if (value == NoteOrder.random &&
                    _hints == HintLevel.fromMemory) {
                  _hints = HintLevel.noNames;
                }
              }),
            ),
            _ChipGroup(
              label: 'Repeats',
              labels: const {1: '1', 2: '2', 3: '3'},
              selected: _repeats,
              onSelected: (value) => setState(() => _repeats = value),
            ),
            _ChipGroup(
              label: 'Hints',
              labels: const {
                HintLevel.full: 'Full',
                HintLevel.noNames: 'No names',
                HintLevel.fromMemory: 'From memory',
              },
              selected: _hints,
              onSelected: (value) => setState(() => _hints = value),
              disabled: _order == NoteOrder.random
                  ? HintLevel.fromMemory
                  : null,
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _start, child: const Text('Start')),
          ],
        ),
      ),
    );
  }
}

class _ChipGroup<T> extends StatelessWidget {
  final String label;
  final Map<T, String> labels;
  final T selected;
  final ValueChanged<T>? onSelected;
  final T? disabled;

  const _ChipGroup({
    required this.label,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    final onSelected = this.onSelected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final MapEntry(key: value, value: text) in labels.entries)
                ChoiceChip(
                  label: Text(text),
                  selected: value == selected,
                  onSelected: onSelected == null || value == disabled
                      ? null
                      : (_) => onSelected(value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
