import 'package:flutter/material.dart';
import 'package:graph/graph/graph_point.dart';

class GraphData {
  final List<GraphPoint> points;
  final Color color;
  final LinearGradient gradient;

  const GraphData({
    required this.points,
    required this.color,
    required this.gradient,
  });
}
