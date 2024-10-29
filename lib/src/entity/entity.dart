import 'package:interactive_chart/src/indicators/indicator.dart';
import 'package:interactive_chart/src/indicators/indicators.dart';

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

  List<Indicators> indicators = [];
  final Map<String, Indicator> indicators1;

  Entity({
    required this.title,
    required this.candles,
    Map<String, Indicator>? indicators,
  }) : this.indicators1 = indicators ?? {};

  void addIndicator(String key, Indicator indicator) {
    indicators1[key] = indicator;
  }

  void removeIndicator(String key) {
    indicators1.remove(key);
  }

  void updateIndicator(String key, Indicator newIndicator) {
    if (indicators1.containsKey(key)) {
      indicators1[key] = newIndicator;
    }
  }

  List<Indicator> get overlayIndicators =>
      indicators1.values.where((i) => i.isOverlay).toList();

  List<Indicator> get separateIndicators =>
      indicators1.values.where((i) => !i.isOverlay).toList();
}
