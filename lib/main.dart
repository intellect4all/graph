import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graph/graph/chart_painter.dart';
import 'package:graph/graph/graph_data.dart';

import 'graph/chart_data.dart';
import 'graph/graph_point.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final graphData = <GraphData>[];
  final notif = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: SizedBox(
          height: 300,
          child: Chart(
            data: graphData,
            dataNormalized: notif,
            labels: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generateRandomGraphData,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _generateRandomGraphData() {
    graphData.clear();
    for (var j = 0; j < 2; j++) {
      final random = Random();
      final points = <GraphPoint>[];
      for (var i = 0; i < 10; i++) {
        points.add(
          GraphPoint(x: i.toDouble(), y: random.nextDouble(), label: "$i"),
        );
      }
      final color = Color.fromARGB(
        255,
        random.nextInt(255),
        random.nextInt(255),
        random.nextInt(255),
      );
      final gradient = LinearGradient(
        colors: [
          color,
          color.withOpacity(0.5),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

      graphData.add(GraphData(
        points: points,
        color: color,
        gradient: gradient,
      ));
    }

    setState(() {});

    dev.log("graphData: $graphData");
    notif.value++;
  }
}

class Chart extends StatefulWidget {
  final List<GraphData> data;
  final List<String> labels;
  final TextStyle? labelStyle;
  final double? labelPadding;
  final ValueNotifier<int> dataNormalized;
  const Chart({
    Key? key,
    required this.data,
    required this.labels,
    this.labelStyle,
    this.labelPadding,
    required this.dataNormalized,
  }) : super(key: key);

  @override
  State<Chart> createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  final List<List<Point>> _normalizedData = [];
  final List<ChartData> _chartData = [];
  final touchedPoint = ValueNotifier<Point?>(null);
  final Random _random = Random();
  @override
  void initState() {
    super.initState();
    _normalizeData();
    widget.dataNormalized.addListener(() {
      _normalizeData();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          width: MediaQuery.of(context).size.width - 50,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              final x = details.localPosition.dx;
              final y = details.localPosition.dy;
              dev.log("x: $x, y: $y");
              final point = Point(x, y);
              touchedPoint.value = point;
            },
            onHorizontalDragEnd: (details) {
              touchedPoint.value = null;
            },
            onTap: () {
              dev.log("tapped");
            },
            child: ValueListenableBuilder<Point?>(
                valueListenable: touchedPoint,
                builder: (context, value, child) {
                  return CustomPaint(
                    willChange: true,
                    painter: ChartPainter(
                      data: _chartData,
                      selectedPoint: value,
                      labelCount: widget.labels.length,
                      getTextAtToolTipPosition: (point) {
                        final x = point.x;
                        final y = point.y;

                        const maxValue = 574390;
                        final yValue = (maxValue * y).toInt();

                        return "\$${yValue.toStringAsFixed(0)}";
                      },
                    ),
                  );
                }),
          ),
        ),
        SizedBox(height: widget.labelPadding ?? 10),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceAround,
        //   children: [
        //     for (var i = 0; i < widget.labels.length; i++)
        //       Text(
        //         widget.labels[i],
        //         style: widget.labelStyle ??
        //             const TextStyle(
        //               color: Colors.black,
        //               fontSize: 12,
        //             ),
        //       ),
        //   ],
        // ),
      ],
    );
  }

  void _normalizeData() {
    _chartData.clear();
    // get the max y value
    num maxY = 0.0;
    for (var i = 0; i < widget.data.length; i++) {
      final points = widget.data[i].points;
      for (var j = 0; j < points.length; j++) {
        final point = points[j];
        if (point.y > maxY) {
          maxY = point.y;
        }
      }
    }

    // normalize the data
    int count = 0;
    for (final data in widget.data) {
      final points = data.points;
      final normalizedPoints = <GraphPoint>[];
      for (var j = 0; j < points.length; j++) {
        final point = points[j];
        dev.log("point.y: ${point.y} maxY: $maxY, x: ${point.x}");
        normalizedPoints.add(
          GraphPoint(
            x: point.x,
            y: point.y / maxY,
            label: point.label,
          ),
        );
      }
      // _normalizedData.add(normalizedPoints);
      dev.log("Adding chart data");
      const red = Color(0xFFEB472C);
      const blue = Color(0xFF2FA0FA);
      _chartData.add(
        ChartData(
          data: normalizedPoints,
          color: count % 2 == 0 ? blue : red,
          gradientColors: count % 2 == 0
              ? [blue.withOpacity(0.2), blue.withOpacity(0.0)]
              : [red.withOpacity(0.2), red.withOpacity(0.0)],
        ),
      );
      count++;
    }
  }
}
