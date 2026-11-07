import 'dart:math';

import '../theory/scale.dart';

enum PracticeDirection { ascending, descending, both }

enum NoteOrder { straight, thirds, groupsOf3, groupsOf4, random }

enum HintLevel { full, noNames, fromMemory }

class PracticeOptions {
  final PracticeDirection direction;
  final NoteOrder order;
  final int repeats;
  final HintLevel hints;

  const PracticeOptions({
    this.direction = PracticeDirection.both,
    this.order = NoteOrder.straight,
    this.repeats = 1,
    this.hints = HintLevel.full,
  });
}

List<ScalePosition> generateSequence(
  List<ScalePosition> positions,
  PracticeOptions options, {
  Random? random,
}) {
  final sequence = <ScalePosition>[];
  if (options.order == NoteOrder.random) {
    final rng = random ?? Random();
    for (var i = 0; i < options.repeats; i++) {
      final pass = [...positions]..shuffle(rng);
      if (sequence.isNotEmpty && pass.first.midi == sequence.last.midi) {
        final repeated = pass.first;
        pass[0] = pass[1];
        pass[1] = repeated;
      }
      sequence.addAll(pass);
    }
    return sequence;
  }
  final pass = _orderedPass(positions, options);
  for (var i = 0; i < options.repeats; i++) {
    final repeatsLastNote =
        sequence.isNotEmpty && pass.first.midi == sequence.last.midi;
    sequence.addAll(repeatsLastNote ? pass.skip(1) : pass);
  }
  return sequence;
}

List<ScalePosition> _orderedPass(
  List<ScalePosition> positions,
  PracticeOptions options,
) {
  final ascending = switch (options.order) {
    NoteOrder.straight || NoteOrder.random => positions,
    NoteOrder.thirds => [
      for (var i = 0; i + 2 < positions.length; i++) ...[
        positions[i],
        positions[i + 2],
      ],
    ],
    NoteOrder.groupsOf3 => _overlappingGroups(positions, 3),
    NoteOrder.groupsOf4 => _overlappingGroups(positions, 4),
  };
  return switch (options.direction) {
    PracticeDirection.ascending => ascending,
    PracticeDirection.descending => ascending.reversed.toList(),
    PracticeDirection.both => [...ascending, ...ascending.reversed.skip(1)],
  };
}

List<ScalePosition> _overlappingGroups(
  List<ScalePosition> positions,
  int size,
) => [
  for (var i = 0; i + size <= positions.length; i++)
    ...positions.sublist(i, i + size),
];
