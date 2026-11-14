import 'package:flutter/material.dart';

class LegendEntry extends StatelessWidget {
  final Color color;
  final String label;

  const LegendEntry({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 7, backgroundColor: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
