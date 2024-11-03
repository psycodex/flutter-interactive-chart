import 'package:interactive_chart/interactive_chart.dart';

class InfoWindowEntity {
  CandleData candle;
  CandleData? previousCandle;

  InfoWindowEntity({required this.candle, this.previousCandle});
}
