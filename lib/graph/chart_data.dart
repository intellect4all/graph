import 'dart:ui';

import 'graph_point.dart';

class ChartData {
  final List<GraphPoint> data;
  final Color color;
  final List<Color> gradientColors;

  const ChartData({
    required this.data,
    required this.color,
    required this.gradientColors,
  });
}
