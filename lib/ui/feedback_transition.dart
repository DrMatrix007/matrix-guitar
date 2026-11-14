import 'package:flutter/material.dart';

class FeedbackTransition extends StatelessWidget {
  final Object value;
  final Widget child;

  const FeedbackTransition({
    super.key,
    required this.value,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180),
    switchInCurve: Curves.easeOut,
    switchOutCurve: Curves.easeIn,
    layoutBuilder: (current, previous) => Stack(
      alignment: Alignment.centerLeft,
      children: [...previous, ?current],
    ),
    child: KeyedSubtree(key: ValueKey(value), child: child),
  );
}
