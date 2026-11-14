import 'package:flutter/material.dart';

import '../theory/scale.dart';

/// Every fret is a key choice, including notes outside the current key.
class FretboardKeySelector extends StatelessWidget {
  final int root;
  final ValueChanged<int> onChanged;

  const FretboardKeySelector({
    super.key,
    required this.root,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key: ${rootName(root)} major',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text(
          'Tap a note to choose home. Swipe for frets 0–12. String 1 is at the top.',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 40),
                  for (var fret = 0; fret <= 12; fret++)
                    SizedBox(width: 48, child: Center(child: Text('$fret'))),
                ],
              ),
              for (var string = 1; string <= 6; string++)
                Row(
                  children: [
                    SizedBox(width: 40, child: Text('S$string')),
                    for (var fret = 0; fret <= 12; fret++)
                      Builder(
                        builder: (context) {
                          final pitch =
                              (openStringMidi[string - 1] + fret) % 12;
                          final selected = pitch == root;
                          return Semantics(
                            label:
                                'Choose ${rootName(pitch)} major, string $string fret $fret',
                            selected: selected,
                            button: true,
                            child: ExcludeSemantics(
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: Material(
                                  color: selected
                                      ? colors.primaryContainer
                                      : colors.surfaceContainerHigh,
                                  child: InkWell(
                                    onTap: () => onChanged(pitch),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: colors.outlineVariant,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          rootName(pitch),
                                          style: TextStyle(
                                            color: selected
                                                ? colors.onPrimaryContainer
                                                : colors.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
