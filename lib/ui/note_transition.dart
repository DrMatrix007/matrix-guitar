import 'package:flutter/material.dart';

/// A single, short emphasis when the selected note changes.
class NoteTransition extends StatelessWidget {
  final Object? selection;
  final Widget Function(BuildContext, double) builder;

  const NoteTransition({
    super.key,
    required this.selection,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey(selection),
      tween: Tween(begin: reducedMotion ? 1 : 0, end: 1),
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => builder(context, value),
    );
  }
}
