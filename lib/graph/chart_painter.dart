import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'chart_data.dart';

typedef GetTextAtToolTipPosition = String Function(math.Point<num> point);

class ToolTipPointData {
  final math.Point<num> point;
  final Color color;

  const ToolTipPointData({
    required this.point,
    required this.color,
  });

  double get x => point.x.toDouble();
  double get y => point.y.toDouble();
}

class ChartPainter extends CustomPainter {
  final List<ChartData> data;
  final int labelCount;
  final math.Point? selectedPoint;
  final GetTextAtToolTipPosition getTextAtToolTipPosition;
  final Color toolTipLineColor;

  late final num _maxValue;
  late final Paint toolTipLinePaint;

  ChartPainter({
    required this.data,
    required this.labelCount,
    required this.selectedPoint,
    required this.getTextAtToolTipPosition,
    this.toolTipLineColor = const Color(0xFFA6B7D4),
  }) {
    _maxValue = data.fold(0, (previousValue, element) {
      final max = element.data.fold(0, (previousValue, element) {
        return math.max(previousValue, element.y.toInt());
      });
      return math.max(previousValue, max);
    });
    toolTipLinePaint = Paint()
      ..color = toolTipLineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;

    // paint curved bezier lines for each data set
    for (final chartData in data) {
      _drawGraphForData(canvas, chartData, height, width);
    }

    // paint selected point
    if (selectedPoint != null) {
      _drawTouchPoint(
        canvas,
        selectedPoint!,
        height,
        width,
      );
    }

    // paint labels
    _drawLabels(canvas, height, width);
  }

  num getHeightRatio(num value, num height) {
    return (value / _maxValue) * (height);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  Path _drawPath(
    List<math.Point<num>> rawData,
    double height,
    double width, {
    bool closePath = false,
  }) {
    /// res: https://www.kodeco.com/32557465-curved-line-charts-in-flutter
    /// https://api.flutter.dev/flutter/dart-ui/Path/cubicTo.html

    // we need to draw a cubic bezier curve for each segment
    // the first segment starts at 0,0 and ends at 1/3, 1/3
    // the second segment starts at 1/3, 1/3 and ends at 2/3, 2/3
    // the third segment starts at 2/3, 2/3 and ends at 1, 1

    // pad the chartData with the first and last point,
    // the point should be lerped to the edge of the graph from the first and last point

    // shift the chartData by 1 to the right
    final chartData = List<math.Point<num>>.from(rawData)
        .map((e) => math.Point(e.x + 1, e.y))
        .toList();

    // first point
    // if (chartData.isNotEmpty) {
    //   final firstPoint = rawData.first;
    //   final firstPointLerp = math.Point(
    //     0,
    //     firstPoint.y + (rawData[1].y - firstPoint.y) / 3,
    //   );
    //
    //   chartData.insert(0, firstPointLerp);
    //
    //   // last point
    //   final lastPoint = rawData.last;
    //   final lastPointLerp = math.Point(
    //     rawData.length - 1,
    //     lastPoint.y + (rawData[rawData.length - 2].y - lastPoint.y) / 3,
    //   );
    //   chartData.add(lastPointLerp);
    // }

    final segmentWidth = width / ((chartData.length - 1) * 3);
    final path = Path();

    // start at the first point
    path.moveTo(0, height - chartData[0].y * height);

    // curved line
    for (var i = 1; i < chartData.length; i++) {
      path.cubicTo(
          (3 * (i - 1) + 1) * segmentWidth,
          height - chartData[i - 1].y * height,
          (3 * (i - 1) + 2) * segmentWidth,
          height - chartData[i].y * height,
          (3 * (i - 1) + 3) * segmentWidth,
          height - chartData[i].y * height);
    }
    path.lineTo(width, height - chartData[chartData.length - 1].y * height);

    // for the gradient fill, we want to close the path
    if (closePath) {
      path.lineTo(width, height);
      path.lineTo(0, height);
    }

    return path;
  }

  void _drawTouchPoint(
    ui.Canvas canvas,
    math.Point<num> selected,
    double height,
    double width,
  ) {
    // point should not go out of bounds horizontally
    final minXPosition = math.min(math.max(selected.x, 0), width);

    final segmentWidth = (width) / ((data.first.data.length - 1));

    // final padding = segmentWidth / 2;

    // use the segment width to determine the current segment on the graph
    final currentSegment = (minXPosition / segmentWidth).round();

    // find the point in each data set that is closest to the current segment
    final pointsOnToolTipLine = data.map((e) {
      final index = e.data.indexWhere((element) {
        return (element.x - currentSegment).abs() < 0.5;
      });

      return ToolTipPointData(point: e.data[index].toPoint(), color: e.color);
    }).toList();

    final xCoordinate = pointsOnToolTipLine.first.point.x;
    final xPosition = xCoordinate * (segmentWidth);

    // draw a line at the point from 0 to the height of the graph, which is the
    // the tooltip line
    canvas.drawLine(
      Offset(xPosition, 0),
      Offset(xPosition, height),
      toolTipLinePaint,
    );

    // draw a circle at the points
    for (int i = 0; i < pointsOnToolTipLine.length; i++) {
      final spotData = pointsOnToolTipLine[i];

      final dotPaint = Paint()
        ..color = spotData.color
        ..strokeWidth = 2
        ..style = PaintingStyle.fill;

      final dotPosition =
          Offset(spotData.x * (segmentWidth), height - spotData.y * height);
      canvas.drawCircle(dotPosition, 4, dotPaint);

      // at the edge of the circle, draw the tooltip text
      final value = getTextAtToolTipPosition(spotData.point);

      final textPainter = _getTextPainter(value)..layout();

      final textWidth = textPainter.width;
      final textHeight = textPainter.height;

      bool isLeft = i % 2 == 0;

      final textPosition = _getTextPositionFromDot(
        dotPosition,
        textWidth,
        textHeight,
        width,
        height,
        isLeft,
        pointsOnToolTipLine,
      );

      //TODO: space out the text so that it doesn't overlap in case of multiple points

      // draw a rect to act as a background for the text
      canvas.drawRect(
        Rect.fromLTWH(
          textPosition.x - 4,
          textPosition.y - 2,
          textWidth + 8,
          textHeight + 4,
        ),
        dotPaint,
      );

      textPainter.paint(
        canvas,
        Offset(
          textPosition.x.toDouble(),
          textPosition.y.toDouble(),
        ),
      );

      canvas.drawCircle(
        dotPosition,
        3,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawGraphForData(
    ui.Canvas canvas,
    ChartData chartData,
    double height,
    double width,
  ) {
    final paint = Paint()
      ..color = chartData.color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final gradientPaint = Paint()
      ..color = chartData.color
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;
    gradientPaint.shader = ui.Gradient.linear(
      Offset.zero,
      Offset(0.0, height),
      chartData.gradientColors,
    );

    final points = chartData.data.map((e) => e.toPoint()).toList();

    final firstPath = _drawPath(points, height, width);
    final secondPath = _drawPath(points, height, width, closePath: true);
    canvas.drawPath(secondPath, gradientPaint);
    canvas.drawPath(firstPath, paint);
  }

  TextPainter _getTextPainter(String value) {
    return TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
  }

  math.Point _getTextPositionFromDot(
      ui.Offset dotPosition,
      double textWidth,
      double textHeight,
      double width,
      double height,
      bool isLeft,
      List<ToolTipPointData> pointsOnToolTipLine) {
    const paddingFromCircle = 3;
    // draw on the left side of the circle if isLeft is true
    // 3 is the padding
    double textX = isLeft
        ? dotPosition.dx - textWidth - paddingFromCircle
        : dotPosition.dx + paddingFromCircle;

    //if isLeft, draw below the circle, else draw above the circle
    double textY = isLeft
        ? dotPosition.dy + paddingFromCircle
        : dotPosition.dy - textHeight - paddingFromCircle;

    // if the text is going out of bounds, move it inside
    if (textX < 0) {
      textX = 0;
    } else if (textX + textWidth > width) {
      textX = width - textWidth;
    }

    if (textY < 0) {
      textY = 0;
    } else if (textY + textHeight > height) {
      textY = height - textHeight;
    }

    return math.Point(textX, textY);
  }

  void _drawLabels(ui.Canvas canvas, double height, double width) {
    const labelTextStyle = TextStyle(
      color: Color(0xFFA6B7D4),
      fontSize: 12,
    );

    // get all x labels
    final xLabels =
        data.first.data.map((e) => (e.label ?? e.x).toString()).toList();

    // get the width of the segment
    final segmentWidth = width / (xLabels.length);

    for (int i = 0; i < xLabels.length; i++) {
      final label = xLabels[i];
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: labelTextStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final textWidth = textPainter.width;
      final textHeight = textPainter.height;

      final labelY = height + textHeight + 5;

      final labelX = segmentWidth / 2;

      final labelPosition = Offset(
        labelX + (i * segmentWidth) - (textWidth / 2),
        labelY,
      );

      textPainter.paint(canvas, labelPosition);
    }
  }
}
