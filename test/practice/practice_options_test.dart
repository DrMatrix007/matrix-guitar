import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_guitar/practice/practice_options.dart';
import 'package:matrix_guitar/theory/scale.dart';

const joinSwapSeed = 4;

final sixPositions = [
  for (var i = 0; i < 6; i++) ScalePosition(string: 1, fret: i, midi: 60 + i),
];

ScaleDefinition scaleOf(String name, PatternKind kind, int root) =>
    ScaleDefinition(
      patterns.singleWhere(
        (pattern) => pattern.name == name && pattern.kind == kind,
      ),
      root,
      defaultFretWindow(root),
    );

List<int> midisOf(List<ScalePosition> sequence) => [
  for (final position in sequence) position.midi,
];

List<int> indicesOf(List<ScalePosition> sequence) => [
  for (final position in sequence) sixPositions.indexOf(position),
];

List<int> indicesFor(
  PracticeDirection direction,
  NoteOrder order, {
  int repeats = 1,
}) => indicesOf(
  generateSequence(
    sixPositions,
    PracticeOptions(direction: direction, order: order, repeats: repeats),
  ),
);

List<int> randomIndices(
  int seed, {
  PracticeDirection direction = PracticeDirection.both,
  int repeats = 1,
}) => indicesOf(
  generateSequence(
    sixPositions,
    PracticeOptions(
      direction: direction,
      order: NoteOrder.random,
      repeats: repeats,
    ),
    random: Random(seed),
  ),
);

void expectEveryPassHoldsEachPosition(List<int> indices) {
  for (var start = 0; start < indices.length; start += sixPositions.length) {
    expect(
      indices.sublist(start, start + sixPositions.length),
      unorderedEquals([0, 1, 2, 3, 4, 5]),
    );
  }
}

bool hasConsecutiveEqualMidis(List<ScalePosition> sequence) {
  for (var i = 1; i < sequence.length; i++) {
    if (sequence[i].midi == sequence[i - 1].midi) return true;
  }
  return false;
}

void main() {
  test('O1 default options run up and down with the top note once', () {
    const options = PracticeOptions();
    final pentatonic = midisOf(
      generateSequence(
        scaleOf('Minor pentatonic', PatternKind.scale, 9).positions,
        options,
      ),
    );
    final major = generateSequence(
      scaleOf('Major', PatternKind.scale, 7).positions,
      options,
    );

    expect(options.direction, PracticeDirection.both);
    expect(options.order, NoteOrder.straight);
    expect(options.repeats, 1);
    expect(options.hints, HintLevel.full);
    expect(pentatonic, hasLength(23));
    expect(pentatonic, pentatonic.reversed.toList());
    expect(pentatonic.where((midi) => midi == 72), hasLength(1));
    expect(major, hasLength(33));
  });

  test('O2 each order and direction gives its literal index sequence', () {
    const expected = [
      (
        order: NoteOrder.straight,
        direction: PracticeDirection.ascending,
        indices: [0, 1, 2, 3, 4, 5],
      ),
      (
        order: NoteOrder.straight,
        direction: PracticeDirection.descending,
        indices: [5, 4, 3, 2, 1, 0],
      ),
      (
        order: NoteOrder.straight,
        direction: PracticeDirection.both,
        indices: [0, 1, 2, 3, 4, 5, 4, 3, 2, 1, 0],
      ),
      (
        order: NoteOrder.thirds,
        direction: PracticeDirection.ascending,
        indices: [0, 2, 1, 3, 2, 4, 3, 5],
      ),
      (
        order: NoteOrder.thirds,
        direction: PracticeDirection.descending,
        indices: [5, 3, 4, 2, 3, 1, 2, 0],
      ),
      (
        order: NoteOrder.thirds,
        direction: PracticeDirection.both,
        indices: [0, 2, 1, 3, 2, 4, 3, 5, 3, 4, 2, 3, 1, 2, 0],
      ),
      (
        order: NoteOrder.groupsOf3,
        direction: PracticeDirection.ascending,
        indices: [0, 1, 2, 1, 2, 3, 2, 3, 4, 3, 4, 5],
      ),
      (
        order: NoteOrder.groupsOf3,
        direction: PracticeDirection.both,
        indices: [
          0, 1, 2, 1, 2, 3, 2, 3, 4, 3, 4, 5, //
          4, 3, 4, 3, 2, 3, 2, 1, 2, 1, 0,
        ],
      ),
      (
        order: NoteOrder.groupsOf4,
        direction: PracticeDirection.ascending,
        indices: [0, 1, 2, 3, 1, 2, 3, 4, 2, 3, 4, 5],
      ),
    ];

    for (final (:order, :direction, :indices) in expected) {
      expect(
        indicesFor(direction, order),
        indices,
        reason: '${order.name} ${direction.name}',
      );
    }
  });

  test('O3 repeats loop the pass and drop the join note', () {
    final ascending = indicesFor(
      PracticeDirection.ascending,
      NoteOrder.straight,
      repeats: 3,
    );
    final both = indicesFor(
      PracticeDirection.both,
      NoteOrder.straight,
      repeats: 3,
    );

    expect(ascending, hasLength(18));
    expect(ascending, [
      0, 1, 2, 3, 4, 5, //
      0, 1, 2, 3, 4, 5, //
      0, 1, 2, 3, 4, 5,
    ]);
    expect(both, hasLength(31));
    expect(both, [
      0, 1, 2, 3, 4, 5, 4, 3, 2, 1, //
      0, 1, 2, 3, 4, 5, 4, 3, 2, 1, //
      0, 1, 2, 3, 4, 5, 4, 3, 2, 1, 0,
    ]);
  });

  test('O4 random passes hold every position, ignore direction and '
      'reproduce from the seed', () {
    for (var seed = 0; seed < 20; seed++) {
      for (var repeats = 1; repeats <= 3; repeats++) {
        final indices = randomIndices(seed, repeats: repeats);

        expect(indices, hasLength(sixPositions.length * repeats));
        expectEveryPassHoldsEachPosition(indices);
        expect(randomIndices(seed, repeats: repeats), indices);
        for (final direction in PracticeDirection.values) {
          expect(
            randomIndices(seed, direction: direction, repeats: repeats),
            indices,
          );
        }
      }
    }
  });

  test('O4 the join swap moves a repeated note off the join', () {
    final rng = Random(joinSwapSeed);
    final firstShuffle = [...sixPositions]..shuffle(rng);
    final secondShuffle = [...sixPositions]..shuffle(rng);

    final indices = randomIndices(joinSwapSeed, repeats: 2);

    expect(secondShuffle.first, firstShuffle.last);
    expect(indices, [
      ...indicesOf(firstShuffle),
      ...indicesOf([
        secondShuffle[1],
        secondShuffle[0],
        ...secondShuffle.skip(2),
      ]),
    ]);
    expect(indices[6], isNot(indices[5]));
    expectEveryPassHoldsEachPosition(indices);
  });

  test('O5 no two consecutive notes are equal across the option grid', () {
    const randomSeeds = [1, 2, 3];
    final failures = <String>[];

    for (final pattern in patterns) {
      for (var root = 0; root < 12; root++) {
        for (final window in fretWindows(root)) {
          final scale = ScaleDefinition(pattern, root, window);
          final positions = scale.positions;
          for (final direction in PracticeDirection.values) {
            for (final order in NoteOrder.values) {
              final seeds = order == NoteOrder.random ? randomSeeds : const [0];
              for (var repeats = 1; repeats <= 3; repeats++) {
                for (final seed in seeds) {
                  final sequence = generateSequence(
                    positions,
                    PracticeOptions(
                      direction: direction,
                      order: order,
                      repeats: repeats,
                    ),
                    random: Random(seed),
                  );
                  if (hasConsecutiveEqualMidis(sequence)) {
                    failures.add(
                      '${scale.name} frets ${window.minFret}-${window.maxFret} '
                      '${direction.name} ${order.name} x$repeats seed $seed',
                    );
                  }
                }
              }
            }
          }
        }
      }
    }

    expect(failures, isEmpty);
  });
}
