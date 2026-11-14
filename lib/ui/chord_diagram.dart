import 'dart:math';

import 'package:flutter/material.dart';

import '../theory/chord.dart';
import 'fretboard.dart';

const _stringCount = 6;
const _displayFrets = 5;

class ChordDiagram extends StatelessWidget {
  final ChordVoicing chord;

  const ChordDiagram({super.key, required this.chord});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.75,
      child: CustomPaint(
        painter: _ChordDiagramPainter(
          chord: chord,
          colors: Theme.of(context).colorScheme,
        ),
      ),
    );
  }
}

class _ChordDiagramPainter extends CustomPainter {
  final ChordVoicing chord;
  final ColorScheme colors;

  _ChordDiagramPainter({required this.chord, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final topMargin = size.height * 0.12;
    final bottomMargin = size.height * 0.06;
    final leftMargin = size.width * 0.1;
    final rightMargin = size.width * 0.05;
    final gridWidth = size.width - leftMargin - rightMargin;
    final gridHeight = size.height - topMargin - bottomMargin;
    final stringSpacing = gridWidth / (_stringCount - 1);
    final fretSpacing = gridHeight / _displayFrets;

    canvas.drawRect(
      Rect.fromLTWH(leftMargin, topMargin, gridWidth, fretSpacing * 0.08),
      Paint()..color = colors.onSurface,
    );

    for (var fret = 0; fret <= _displayFrets; fret++) {
      final y = topMargin + fret * fretSpacing;
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(leftMargin + gridWidth, y),
        Paint()
          ..color = colors.outlineVariant
          ..strokeWidth = 1.5,
      );
    }

    for (var string = 0; string < _stringCount; string++) {
      final x = leftMargin + string * stringSpacing;
      canvas.drawLine(
        Offset(x, topMargin),
        Offset(x, topMargin + gridHeight),
        Paint()
          ..color = colors.outline
          ..strokeWidth = 1.0 + (_stringCount - 1 - string) * 0.3,
      );
    }

    final dotRadius = min(stringSpacing, fretSpacing) * 0.32;
    for (var i = 0; i < _stringCount; i++) {
      final x = leftMargin + i * stringSpacing;
      final fret = chord.frets[i];

      if (fret < 0) {
        _paintText(
          canvas,
          '×',
          Offset(x, topMargin - topMargin * 0.4),
          colors.onSurfaceVariant,
          dotRadius * 1.8,
        );
      } else if (fret == 0) {
        canvas.drawCircle(
          Offset(x, topMargin - topMargin * 0.4),
          dotRadius * 0.65,
          Paint()
            ..color = colors.onSurfaceVariant
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      } else {
        final fretPos = fret - 1;
        final y = topMargin + (fretPos + 0.5) * fretSpacing;
        final isRoot = chord.midiNotes[i]! % 12 == chord.root;
        final fill = isRoot ? colors.primary : highlightFill;
        final onFill = isRoot ? colors.onPrimary : Colors.black;

        canvas.drawCircle(Offset(x, y), dotRadius, Paint()..color = fill);
        _paintText(canvas, '$fret', Offset(x, y), onFill, dotRadius * 1.1);
      }
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double fontSize,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - painter.size.center(Offset.zero));
    painter.dispose();
  }

  @override
  bool shouldRepaint(_ChordDiagramPainter oldDelegate) =>
      oldDelegate.chord != chord || oldDelegate.colors != colors;
}
