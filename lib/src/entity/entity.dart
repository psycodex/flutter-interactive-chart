import 'candle_data.dart';

class Entity {
  String title;

  /// The full list of [CandleData] to be used for this chart.
  ///
  /// It needs to have at least 3 data points. If data is sufficiently large,
  /// the chart will default to display the most recent 90 data points when
  /// first opened (configurable with [initialVisibleCandleCount] parameter),
  /// and allow users to freely zoom and pan however they like.
  List<CandleData> candles;

  Entity(this.title, this.candles);
}
