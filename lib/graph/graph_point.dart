import 'dart:math';

class GraphPoint {
  final double x;
  final double y;
  final String? label;

  const GraphPoint({
    required this.x,
    required this.y,
    required this.label,
  });

  Point toPoint() {
    return Point(
      x,
      y,
    );
  }
}
