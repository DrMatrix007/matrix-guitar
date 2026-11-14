import 'dart:math';

import 'package:flutter/material.dart';

import '../theory/scale.dart';

const _aspectRatio = 1.5;
const _stringCount = 6;
const highlightFill = Color(0xFFFFB300);
const _onHighlightFill = Colors.black;

class Fretboard extends StatelessWidget {
  final ScaleDefinition scale;
  final ScalePosition? highlight;
  final bool showNames;

  const Fretboard({
    super.key,
    required this.scale,
    this.highlight,
    this.showNames = true,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: CustomPaint(
        painter: _FretboardPainter(
          scale: scale,
          positions: scale.positions,
          highlight: highlight,
          showNames: showNames,
          colors: Theme.of(context).colorScheme,
        ),
      ),
    );
  }
}

class _FretboardPainter extends CustomPainter {
  final ScaleDefinition scale;
  final List<ScalePosition> positions;
  final ScalePosition? highlight;
  final bool showNames;
  final ColorScheme colors;

  _FretboardPainter({
    required this.scale,
    required this.positions,
    required this.highlight,
    required this.showNames,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final firstFret = max(scale.minFret, 1);
    final columns = scale.maxFret - firstFret + 2;
    final columnWidth = size.width / columns;
    final rowHeight = size.height / (_stringCount + 1);
    final boardHeight = rowHeight * _stringCount;

    canvas.drawRect(
      Offset.zero & Size(size.width, boardHeight),
      Paint()..color = colors.surfaceContainerHigh,
    );

    for (var column = 1; column <= columns; column++) {
      final isNut = column == 1;
      final x = column * columnWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, boardHeight),
        Paint()
          ..color = isNut ? colors.onSurface : colors.outlineVariant
          ..strokeWidth = rowHeight * (isNut ? 0.16 : 0.06),
      );
    }

    for (var string = 1; string <= _stringCount; string++) {
      final y = (string - 0.5) * rowHeight;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = colors.outline
          ..strokeWidth = rowHeight * 0.015 * (string + 1),
      );
    }

    for (var column = 0; column < columns; column++) {
      _paintText(
        canvas,
        '${column == 0 ? 0 : firstFret + column - 1}',
        Offset((column + 0.5) * columnWidth, boardHeight + rowHeight / 2),
        colors.onSurfaceVariant,
        rowHeight * 0.4,
      );
    }

    for (final position in positions) {
      final column = position.fret == 0 ? 0 : position.fret - firstFret + 1;
      final center = Offset(
        (column + 0.5) * columnWidth,
        (position.string - 0.5) * rowHeight,
      );
      final isHighlight = position.midi == highlight?.midi;
      final (fill, onFill) = isHighlight
          ? (highlightFill, _onHighlightFill)
          : scale.isRoot(position.midi)
          ? (colors.primary, colors.onPrimary)
          : (colors.secondaryContainer, colors.onSecondaryContainer);

      canvas.drawCircle(center, rowHeight * 0.42, Paint()..color = fill);
      if (isHighlight) {
        canvas.drawCircle(
          center,
          rowHeight * 0.5,
          Paint()
            ..color = highlightFill
            ..style = PaintingStyle.stroke
            ..strokeWidth = rowHeight * 0.06,
        );
      }
      if (showNames) {
        _paintText(
          canvas,
          scale.spelledPitchClass(position.midi),
          center,
          onFill,
          rowHeight * 0.4,
        );
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
  bool shouldRepaint(_FretboardPainter oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.highlight != highlight ||
      oldDelegate.showNames != showNames;
}
