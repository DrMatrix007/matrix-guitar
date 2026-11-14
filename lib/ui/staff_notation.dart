import 'dart:math';

import 'package:flutter/material.dart';

import 'fretboard.dart';

class StaffNote {
  final int midi;
  final String name;

  const StaffNote(this.midi, this.name);

  int get accidental =>
      '#'.allMatches(name).length - 'b'.allMatches(name).length;
  int get letter => 'CDEFGAB'.indexOf(name[0]);
  int get octave =>
      (midi - [0, 2, 4, 5, 7, 9, 11][letter] - accidental) ~/ 12 - 1;
  int get staffStep => octave * 7 + letter - 30;
  String get label => '$name$octave';
}

class StaffNotation extends StatelessWidget {
  final List<StaffNote> notes;
  final int selectedIndex;

  const StaffNotation({
    super.key,
    required this.notes,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Treble staff, sounding pitches: ${notes.indexed.map((entry) => '${entry.$2.label}${entry.$1 == selectedIndex ? ', selected' : ''}').join('; ')}',
    child: SizedBox(
      height: 190,
      width: double.infinity,
      child: CustomPaint(
        painter: _StaffPainter(
          notes,
          selectedIndex,
          Theme.of(context).colorScheme,
        ),
      ),
    ),
  );
}

class _StaffPainter extends CustomPainter {
  final List<StaffNote> notes;
  final int selectedIndex;
  final ColorScheme colors;

  _StaffPainter(this.notes, this.selectedIndex, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final low = min(-2, notes.map((n) => n.staffStep).reduce(min));
    final high = max(10, notes.map((n) => n.staffStep).reduce(max));
    final step = min(6.0, (size.height - 65) / (high - low));
    final bottom = 28 + high * step;
    double y(int pitch) => bottom - pitch * step;
    final line = Paint()..color = colors.outline;
    for (var i = 0; i <= 8; i += 2) {
      canvas.drawLine(Offset(8, y(i)), Offset(size.width - 8, y(i)), line);
    }
    _text(canvas, '𝄞', Offset(22, y(4)), 48, colors.onSurface);
    final width = (size.width - 62) / notes.length;
    for (final (index, note) in notes.indexed) {
      final x = 56 + width * (index + .5);
      final center = Offset(x, y(note.staffStep));
      final color = index == selectedIndex ? highlightFill : colors.onSurface;
      for (var ledger = -2; ledger >= note.staffStep; ledger -= 2) {
        canvas.drawLine(
          Offset(x - 12, y(ledger)),
          Offset(x + 12, y(ledger)),
          line,
        );
      }
      for (var ledger = 10; ledger <= note.staffStep; ledger += 2) {
        canvas.drawLine(
          Offset(x - 12, y(ledger)),
          Offset(x + 12, y(ledger)),
          line,
        );
      }
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 13, height: 9),
        Paint()..color = color,
      );
      final stemUp = note.staffStep < 4;
      final stemX = x + (stemUp ? 6 : -6);
      canvas.drawLine(
        Offset(stemX, center.dy),
        Offset(stemX, center.dy + (stemUp ? -28 : 28)),
        Paint()
          ..color = color
          ..strokeWidth = 1.5,
      );
      final accidental = note.name
          .substring(1)
          .replaceAll('#', '♯')
          .replaceAll('b', '♭');
      _text(
        canvas,
        accidental.isEmpty ? '♮' : accidental,
        Offset(x - 19, center.dy),
        17,
        colors.onSurface,
      );
      _text(
        canvas,
        note.label,
        Offset(x, size.height - 15),
        13,
        colors.onSurface,
      );
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: size, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - painter.size.center(Offset.zero));
    painter.dispose();
  }

  @override
  bool shouldRepaint(_StaffPainter oldDelegate) =>
      oldDelegate.notes != notes ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.colors != colors;
}
