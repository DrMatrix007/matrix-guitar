import 'package:flutter/material.dart';

import '../audio/audio_source.dart';
import '../theory/harmony.dart';
import '../theory/scale.dart';
import 'theory_play_screen.dart';

enum TheoryMode {
  chordTones('Chord-tone targeting'),
  guideTones('Guide-tone voice leading'),
  transposition('Progression transposition'),
  construction('Construction & inversions');

  const TheoryMode(this.label);
  final String label;
}

class TheoryPracticeScreen extends StatefulWidget {
  final AudioSource Function(List<ScalePosition>) audioSourceFactory;

  const TheoryPracticeScreen({super.key, required this.audioSourceFactory});

  @override
  State<TheoryPracticeScreen> createState() => _TheoryPracticeScreenState();
}

class _TheoryPracticeScreenState extends State<TheoryPracticeScreen> {
  int _key = 0;
  int _progression = 0;
  TheoryMode _mode = TheoryMode.chordTones;
  ChordTone _tone = ChordTone.third;
  int _selectedInversion = 0;
  bool _started = false;
  int _index = 0;
  int _wrong = 0;
  String? _feedback;
  bool _correct = false;
  late List<HarmonyChord> _chords;
  late List<HarmonyTarget> _targets;

  static const _window = (minFret: 3, maxFret: 7);

  void _prepare() {
    _chords = harmonyProgressions[_progression].chords(_key, _window);
    _targets = harmonyTargets(
      _chords,
      tone: _tone,
      guideTones: _mode == TheoryMode.guideTones,
    );
    _index = 0;
    _wrong = 0;
    _feedback = null;
    _correct = false;
  }

  int get _count => _chords.length * (_mode == TheoryMode.construction ? 2 : 1);
  HarmonyChord get _chord =>
      _chords[_mode == TheoryMode.construction ? _index ~/ 2 : _index];

  String get _answer => switch (_mode) {
    TheoryMode.chordTones || TheoryMode.guideTones =>
      _targets[_index].chord.toneName(_targets[_index].tone),
    TheoryMode.transposition => _chord.name,
    TheoryMode.construction =>
      _index.isEven
          ? _chord.function.quality.formula
          : _chord.noteNames[_selectedInversion],
  };

  String get _question => switch (_mode) {
    TheoryMode.chordTones =>
      'What is the chord-relative ${_tone.label} of ${_chord.name}?',
    TheoryMode.guideTones =>
      _index == 0
          ? 'Choose the starting third or seventh nearest middle C (C4) in frets 3–7 for ${_chord.name}.'
          : 'From ${_targets[_index - 1].chord.keyScale.spelledNote(_targets[_index - 1].position.midi)}, which third or seventh of ${_chord.name} needs the smallest movement in frets 3–7?',
    TheoryMode.transposition =>
      'In ${rootName(_key)} major, which chord is ${_chord.function.roman}?',
    TheoryMode.construction =>
      _index.isEven
          ? 'Which chord-relative interval formula builds ${_chord.name}?'
          : 'Which bass note gives ${_chord.name} ${['root position', 'first inversion', 'second inversion', 'third inversion'][_selectedInversion]}?',
  };

  List<String> get _choices {
    final choices = switch (_mode) {
      TheoryMode.chordTones || TheoryMode.guideTones => <String>{
        _answer,
        for (var pitch = 0; pitch < 12; pitch++)
          if (pitch != _targets[_index].position.midi % 12)
            _chord.keyScale.spelledPitchClass(pitch),
      },
      TheoryMode.transposition => <String>{
        for (final root in _chord.keyScale.noteNames)
          '$root${_chord.function.quality.suffix}',
        for (final quality in HarmonyQuality.values)
          '${_chord.keyScale.noteNames[_chord.function.degree]}${quality.suffix}',
      },
      TheoryMode.construction =>
        _index.isEven
            ? HarmonyQuality.values.map((q) => q.formula).toSet()
            : _chord.noteNames.toSet(),
    };
    return choices.toList()..sort();
  }

  String get _explanation => switch (_mode) {
    TheoryMode.chordTones ||
    TheoryMode.guideTones => _targets[_index].explanation,
    TheoryMode.transposition =>
      '${_chord.function.roman} is ${_chord.name} in ${rootName(_key)} major. Count the key notes ${_chord.keyScale.noteNames.join('–')}: note ${_chord.function.degree + 1} is ${_chord.noteNames.first}. Apply ${_chord.function.quality.formula} to that root to get ${_chord.noteNames.join('–')}. ${_chord.function.explanation}',
    TheoryMode.construction =>
      _index.isEven
          ? '${_chord.name}: ${_chord.function.quality.formula}. Notes: ${_chord.noteNames.join('–')}, at ${_chord.intervals.join(', ')} semitones above ${_chord.noteNames.first}. ${_chord.function.explanation}'
          : 'Bass to top: ${_chord.inversionNames(_selectedInversion).join('–')}. Put the ${ChordTone.values[_selectedInversion].label}, ${_chord.noteNames[_selectedInversion]}, lowest. The bass determines the inversion; the chord root remains ${_chord.noteNames.first}.',
  };

  String get _method => switch (_mode) {
    TheoryMode.chordTones => 'Start from the chord root, not the key home note. Use its quality: a major third is 4 semitones, a minor third 3, a fifth 7, a major seventh 11 and a flat seventh 10. The root is 0.',
    TheoryMode.guideTones => 'Find the third and seventh of the new chord, then compare their available pitches in frets 3–7 with the previous note. Choose the smallest distance; ties use the lower pitch. Start nearest middle C (C4). Triads offer only their third.',
    TheoryMode.transposition => 'Count the Roman numeral from the home note of the major key to find the chord root. Then use the numeral’s case and suffix for its quality. For V/ii, find ii first and build its dominant seventh.',
    TheoryMode.construction => 'For a formula, identify the chord quality and count intervals from its root. For an inversion, put the root, third, fifth or seventh lowest for root position, first, second or third inversion. The root keeps its name.',
  };

  void _submit(String choice) {
    setState(() {
      _correct = choice == _answer;
      if (!_correct) _wrong++;
      _feedback =
          '${_correct ? 'Correct.' : 'Try again. The answer is $_answer.'} $_explanation';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _started ? _quiz(context) : _setup(context),
    );
  }

  List<Widget> _setup(BuildContext context) {
    final chords = harmonyProgressions[_progression].chords(_key, _window);
    final first = chords.first;
    final example = switch (_mode) {
      TheoryMode.chordTones =>
        '${first.name} contains ${first.noteNames.join('–')}. Its ${_tone.label} is ${first.toneName(_tone)}, ${first.intervals[_tone.index]} semitones above ${first.noteNames.first}.',
      TheoryMode.guideTones =>
        harmonyTargets(chords, guideTones: true)
            .map(
              (t) =>
                  '${t.chord.name}: ${t.chord.keyScale.spelledNote(t.position.midi)} (${t.tone.label})',
            )
            .join(' → '),
      TheoryMode.transposition =>
        'In ${rootName(_key)} major, count ${first.keyScale.noteNames.join('–')}. ${first.function.roman} uses note ${first.function.degree + 1}, ${first.noteNames.first}, as its root: ${first.name}.',
      TheoryMode.construction =>
        '${first.name} uses ${first.function.quality.formula}: ${first.noteNames.join('–')}. With ${first.noteNames[_selectedInversion]} in the bass (lowest note), the order is ${first.inversionNames(_selectedInversion).join('–')}. The root is still ${first.noteNames.first}.',
    };
    return [
      Text('Theory practice', style: Theme.of(context).textTheme.headlineSmall),
      const Text(
        'Learn how chords fit a key, then find their notes on your guitar. Start with chord-tone targeting (root, then third), try construction and transposition, then guide tones.',
      ),
      const ExpansionTile(
        key: PageStorageKey('theory-basics'),
        title: Text('Music theory basics'),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            'A key is a family of notes with a home note: C major feels at home on C. A chord is several notes together; its root names it. Dm7 has root D even in the key of C.',
          ),
          SizedBox(height: 8),
          Text(
            'A semitone is one fret on the same string. An interval is the distance between notes. Count the root as 1: C–E–G gives 1–3–5. A major third is 4 semitones; a minor third is 3. A fifth is 7.',
          ),
          SizedBox(height: 8),
          Text(
            'b (flat) lowers a note or interval by one semitone; # (sharp) raises it by one. These signs are called accidentals. In a formula, b3 means one semitone below the major third. Repeated signs lower or raise twice.',
          ),
          SizedBox(height: 8),
          Text(
            'A triad has root, third and fifth. A seventh chord adds a seventh: maj7 is 11 semitones above the root; 7 means a flat seventh, 10 semitones. Cmaj7 is C–E–G–B; C7 is C–E–G–Bb. m means minor: Cm is C–Eb–G.',
          ),
          SizedBox(height: 8),
          Text(
            'Roman numerals count roots within the key: I, ii, iii, IV, V, vi, vii mean 1 through 7. Uppercase means major, lowercase minor here; suffixes add sevenths. In C major, ii is Dm, but the third of Dm is F. Key degree 2 and chord degree 3 count from different starting notes.',
          ),
          SizedBox(height: 8),
          Text(
            'A progression is a sequence of chords. Transposing keeps the same Roman numerals while moving the home note to another key. An inversion keeps the same chord notes but changes the bass, the lowest note.',
          ),
        ],
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<int>(
        initialValue: _key,
        decoration: const InputDecoration(labelText: 'Major key'),
        items: [
          for (var key = 0; key < 12; key++)
            DropdownMenuItem(value: key, child: Text('${rootName(key)} major')),
        ],
        onChanged: (value) => setState(() => _key = value!),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        initialValue: _progression,
        decoration: const InputDecoration(labelText: 'Progression'),
        items: [
          for (final (i, p) in harmonyProgressions.indexed)
            DropdownMenuItem(value: i, child: Text(p.name)),
        ],
        onChanged: (value) => setState(() {
          _progression = value!;
          if (!harmonyProgressions[_progression].hasSevenths &&
              _tone == ChordTone.seventh) {
            _tone = ChordTone.third;
          }
          if (!harmonyProgressions[_progression].hasSevenths &&
              _selectedInversion == 3) {
            _selectedInversion = 0;
          }
        }),
      ),
      const SizedBox(height: 12),
      for (final mode in TheoryMode.values)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            _mode == mode ? Icons.radio_button_checked : Icons.radio_button_off,
          ),
          title: Text(mode.label),
          onTap: () => setState(() => _mode = mode),
        ),
      if (_mode == TheoryMode.chordTones) ...[
        Wrap(
          spacing: 8,
          children: [
            for (final tone in ChordTone.values)
              ChoiceChip(
                label: Text(tone.label),
                selected: _tone == tone,
                onSelected:
                    tone == ChordTone.seventh &&
                        !harmonyProgressions[_progression].hasSevenths
                    ? null
                    : (_) => setState(() => _tone = tone),
              ),
          ],
        ),
        const Text(
          'Seventh targeting is available for ii7–V7–Imaj7; triads have no seventh.',
        ),
      ],
      if (_mode == TheoryMode.construction)
        Wrap(
          spacing: 8,
          children: [
            for (var inversion = 0; inversion < 4; inversion++)
              ChoiceChip(
                label: Text(
                  [
                    'Root position',
                    'First inversion',
                    'Second inversion',
                    'Third inversion',
                  ][inversion],
                ),
                selected: _selectedInversion == inversion,
                onSelected:
                    inversion == 3 &&
                        !harmonyProgressions[_progression].hasSevenths
                    ? null
                    : (_) => setState(() => _selectedInversion = inversion),
              ),
          ],
        ),
      if (_mode == TheoryMode.guideTones)
        const Text(
          'Guide tones are thirds and sevenths: they make the chord quality clear. Voice leading means moving smoothly between chords.',
        ),
      ExpansionTile(
        key: const PageStorageKey('theory-exercise'),
        title: const Text('How this exercise works'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(_method),
          const SizedBox(height: 8),
          Text(
            'Selected progression: ${chords.map((c) => c.name).join(' → ')}.',
          ),
          const SizedBox(height: 8),
          Text('Worked example: $example'),
          if (_progression == 2) ...[
            const SizedBox(height: 8),
            Text(
              'V/ii means “five of two”. ${chords[1].name} (${chords[1].noteNames.join('–')}) leads to ${chords[2].name}, a temporary home. Its ${chords[1].noteNames[1]} lies outside this major key.',
            ),
          ],
          if (_progression == 3) ...[
            const SizedBox(height: 8),
            Text(
              'Borrowed iv: ${chords[1].name} becomes ${chords[2].name} by lowering ${chords[1].noteNames[1]} to ${chords[2].noteNames[1]}. It borrows from ${rootName(_key)} minor, which has the same home note.',
            ),
          ],
        ],
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () => setState(() {
          _prepare();
          _started = true;
        }),
        child: const Text('Start quiz'),
      ),
      if (_mode == TheoryMode.chordTones || _mode == TheoryMode.guideTones)
        OutlinedButton(
          onPressed: () {
            _prepare();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TheoryPlayScreen(
                  targets: _targets,
                  audioSourceFactory: widget.audioSourceFactory,
                ),
              ),
            );
          },
          child: const Text('Play single notes'),
        ),
      const SizedBox(height: 24),
      const ExpansionTile(
        key: PageStorageKey('theory-advanced'),
        title: Text('Advanced example · ungraded'),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            'A shell voicing keeps only a few essential chord notes. Chord melody puts a tune above chord notes. Try these after single notes feel comfortable.',
          ),
          Text(
            'In C: Dm7 → G7 → Cmaj7. Try shells F–C → F–B → E–B; C falls to B, then F falls to E. For chord melody, place D → D → E above those shells. Try each voice alone before combining them. These are ordered low-to-high note examples, not a prescribed guitar shape.',
          ),
          Text(
            'Theory microphone practice grades one note at a time, including octave. It cannot grade polyphonic voicings, inversions or chord melody. Mute other strings between notes.',
          ),
        ],
      ),
    ];
  }

  List<Widget> _quiz(BuildContext context) {
    if (_index == _count) {
      return [
        Text(
          'Practice complete',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text('$_count questions completed · $_wrong incorrect attempts'),
        FilledButton(
          onPressed: () => setState(() {
            _prepare();
          }),
          child: const Text('Retry quiz'),
        ),
        OutlinedButton(
          onPressed: () => setState(() => _started = false),
          child: const Text('Back to setup'),
        ),
      ];
    }
    return [
      Text(
        '${rootName(_key)} major · ${harmonyProgressions[_progression].name}',
      ),
      Text('Question ${_index + 1} of $_count · $_wrong incorrect attempts'),
      LinearProgressIndicator(value: _index / _count),
      const SizedBox(height: 16),
      Text('Key-relative function: ${_chord.function.roman}'),
      Text(_question, style: Theme.of(context).textTheme.titleLarge),
      ExpansionTile(
        title: const Text('Remember the method'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [Text(_method)],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final choice in _choices)
            OutlinedButton(
              onPressed: _correct ? null : () => _submit(choice),
              child: Text(choice),
            ),
        ],
      ),
      if (_feedback != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(_feedback!),
        ),
      if (_correct)
        FilledButton(
          onPressed: () => setState(() {
            _index++;
            _feedback = null;
            _correct = false;
          }),
          child: Text(_index + 1 == _count ? 'Finish' : 'Next'),
        ),
      TextButton(
        onPressed: () => setState(() => _started = false),
        child: const Text('Back to setup'),
      ),
    ];
  }
}
