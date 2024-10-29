import 'package:interactive_chart/src/entity/volume_entity.dart';

import 'cci_entity.dart';
import 'kdj_entity.dart';
import 'macd_entity.dart';
import 'rsi_entity.dart';
import 'rw_entity.dart';

class CandleData
    with KDJEntity, RSIEntity, WREntity, CCIEntity, MACDEntity, VolumeEntity {
  /// The timestamp of this data point, in milliseconds since epoch.
  final int timestamp;

  /// The "open" price of this data point. It's acceptable to have null here for
  /// a few data points, but they must not all be null. If either [open] or
  /// [close] is null for a data point, it will appear as a gap in the chart.
  final double open;

  /// The "high" price. If either one of [high] or [low] is null, we won't
  /// draw the narrow part of the candlestick for that data point.
  final double high;

  /// The "low" price. If either one of [high] or [low] is null, we won't
  /// draw the narrow part of the candlestick for that data point.
  final double low;

  /// The "close" price of this data point. It's acceptable to have null here
  /// for a few data points, but they must not all be null. If either [open] or
  /// [close] is null for a data point, it will appear as a gap in the chart.
  final double close;

  /// The volume information of this data point.
  final double? volume;

  /// The change of the close price from the previous data point.
  final double change;

  /// Data holder for additional trend lines, for this data point.
  ///
  /// For a single trend line, we can assign it as a list with a single element.
  /// For example if we want "7 days moving average", do something like
  /// `trends = [ma7]`. If there are multiple tread lines, we can assign a list
  /// with multiple elements, like `trends = [ma7, ma30]`.
  /// If we don't want any trend lines, we can assign an empty list.
  ///
  /// This should be an unmodifiable list, so please do not use `add`
  /// or `clear` methods on the list. Always assign a new list if values
  /// are changed. Otherwise the UI might not be updated.
  Map<int, double?> maLines = {};

//  Upper rail line
  double? up;

//  Central rail line
  double? mb;

//  lower rail line
  double? dn;

  double? BOLLMA;

  static bool forceUpdate = false;

  CandleData({
    required this.timestamp,
    required this.open,
    required this.close,
    required this.volume,
    required this.high,
    required this.low,
    List<double?>? trends,
  }) : this.change = open != 0 ? (close - open) / open * 100 : 0;

  @override
  String toString() => "<CandleData ($timestamp: $close)>";
}
