import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart';
import 'package:intl/intl.dart';
import 'mock_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<CandleData> _data = MockDataTesla.candles;
  bool _darkMode = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _darkMode ? Brightness.dark : Brightness.light,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Interactive Chart Demo"),
          actions: [
            IconButton(
              icon: Icon(_darkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: () => setState(() => _darkMode = !_darkMode),
            ),
          ],
        ),
        body: InteractiveChart(
          entity: Entity(
            title: "Tesla Inc. (TSLA)",
            candles: _data,
          ),
          style: ChartStyle(
            priceGainColor: Colors.green,
            priceLossColor: Colors.red,
            volumeColor: Colors.teal.withOpacity(0.8),
            maStyles: {
              7: Paint()
                ..strokeWidth = 2.0
                ..strokeCap = StrokeCap.round
                ..color = Colors.deepOrange,
              30: Paint()
                ..strokeWidth = 4.0
                ..strokeCap = StrokeCap.round
                ..color = Colors.orange,
              90: Paint()
                ..strokeWidth = 4.0
                ..strokeCap = StrokeCap.round
                ..color = Colors.blue,
            },
            priceGridLineColor: Colors.blue[200]!,
            priceLabelStyle: TextStyle(color: Colors.blue[200]),
            timeLabelStyle: TextStyle(color: Colors.blue[200]),
            selectionHighlightColor: Colors.red.withOpacity(0.2),
            overlayBackgroundColor: Colors.red[900]!.withOpacity(0.6),
            overlayTextStyle: TextStyle(color: Colors.red[100]),
            timeLabelHeight: 32,
            volumeHeightFactor: 0.2, // volume area is 20% of total height
          ),
          /** Customize axis labels */
          timeLabel: (timestamp, visibleDataCount) {
            final DateTime dateTime =
                DateTime.fromMillisecondsSinceEpoch(timestamp);
            final DateFormat formatter = DateFormat('yyyy-MM-dd');
            return formatter.format(dateTime);
          },
          priceLabel: (price) => "${price.round()}",
          /** Customize overlay (tap and hold to see it)
           ** Or return an empty object to disable overlay info. */
          // overlayInfo: (candle) => {
          //   "Hi": "${candle.high?.toStringAsFixed(2)}",
          //   "Lo": "${candle.low?.toStringAsFixed(2)}",
          // },
          /** Callbacks */
          // onTap: (candle) => print("user tapped on $candle"),
          // onCandleResize: (width) => print("each candle is $width wide"),
        ),
      ),
    );
  }
}
