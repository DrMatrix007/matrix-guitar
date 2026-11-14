import 'package:flutter/material.dart';

import '../theory/harmony.dart';
import '../theory/scale.dart';
import 'fretboard.dart';
import 'staff_notation.dart';

class TheoryVisualization extends StatefulWidget {
  final List<HarmonyChord> chords;
  final ChordTone tone;
  final int inversion;
  final bool guideTones;
  final HarmonyTarget? target;

  const TheoryVisualization({
    super.key,
    required this.chords,
    this.tone = ChordTone.third,
    this.inversion = 0,
    this.guideTones = false,
    this.target,
  });

  @override
  State<TheoryVisualization> createState() => _TheoryVisualizationState();
}

class _TheoryVisualizationState extends State<TheoryVisualization> {
  int _chordIndex = 0;
  ChordTone? _tone;

  @override
  Widget build(BuildContext context) {
    final chord = widget.target?.chord ?? widget.chords[_chordIndex];
    final targets = harmonyTargets(
      widget.chords,
      guideTones: widget.guideTones,
      tone: widget.tone,
    );
    final target = widget.target ?? targets[_chordIndex];
    final tone = widget.target != null || widget.guideTones
        ? target.tone
        : _tone ?? widget.tone;
    final order = [
      ...chord.tones.skip(widget.inversion),
      ...chord.tones.take(widget.inversion),
    ];
    var previous = 42;
    final positions = <ScalePosition>[];
    for (final tone in order) {
      final position = chord.scale.positions.firstWhere(
        (p) => p.midi > previous && p.midi % 12 == chord.pitchClass(tone),
      );
      positions.add(position);
      previous = position.midi;
    }
    final selectedPosition = widget.target != null || widget.guideTones
        ? target.position
        : positions[order.indexOf(tone)];
    final notes = widget.target != null
        ? [StaffNote(target.position.midi, chord.toneName(target.tone))]
        : widget.guideTones
        ? [
            for (final t in targets)
              StaffNote(t.position.midi, t.chord.toneName(t.tone)),
          ]
        : [
            for (final (i, p) in positions.indexed)
              StaffNote(p.midi, chord.toneName(order[i])),
          ];
    final selectedIndex = widget.target != null
        ? 0
        : widget.guideTones
        ? _chordIndex
        : order.indexOf(tone);
    final staff = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Standard notation · treble clef'),
        const Text(
          'Sounding pitches (middle C = C4); accidentals shown on every note.',
        ),
        StaffNotation(notes: notes, selectedIndex: selectedIndex),
      ],
    );
    final board = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fretboard · frets 3–7 · string 1 at top'),
        Semantics(
          label:
              '${notes[selectedIndex].label}, string ${selectedPosition.string}, fret ${selectedPosition.fret}, selected',
          child: Fretboard(
            scale: chord.scale,
            highlight: selectedPosition,
            noteName: (midi) =>
                chord.noteNames[chord.intervals.indexOf(
                  (midi - chord.root) % 12,
                )],
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.target == null) ...[
          Wrap(
            spacing: 8,
            children: [
              for (final (index, c) in widget.chords.indexed)
                ChoiceChip(
                  label: Text('${c.function.roman} · ${c.name}'),
                  selected: _chordIndex == index,
                  onSelected: (_) => setState(() {
                    _chordIndex = index;
                    _tone = null;
                  }),
                ),
            ],
          ),
          if (!widget.guideTones)
            Wrap(
              spacing: 8,
              children: [
                for (final t in chord.tones)
                  ChoiceChip(
                    label: Text('${t.label} · ${chord.toneName(t)}'),
                    selected: tone == t,
                    onSelected: (_) => setState(() => _tone = t),
                  ),
              ],
            ),
          Text(
            widget.guideTones
                ? 'Guide-tone path · select a chord to locate its note.'
                : 'Ascending chord tones · bass to top: ${chord.inversionNames(widget.inversion).join('–')}. Illustrative single notes, not a simultaneous guitar voicing.',
          ),
        ],
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 700
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: staff),
                    const SizedBox(width: 24),
                    Expanded(child: board),
                  ],
                )
              : Column(children: [staff, board]),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
