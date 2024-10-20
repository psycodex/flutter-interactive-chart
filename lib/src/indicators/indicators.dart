import 'package:interactive_chart/src/indicators/moving_average.dart';

enum IndicatorsType { MA, BOLL, MACD, KDJ, RSI, WR, CCI }

abstract class Indicators {
  final IndicatorsType indicators;
  final bool isShow;
  int length;

  Indicators(this.indicators, this.length, this.isShow);

  Map<String, dynamic> toJson() => {
        'indicators': indicators.toString().split('.').last,
        'isShow': isShow,
        'length': length,
      };

  static Indicators fromJson(Map<String, dynamic> json) {
    final type = IndicatorsType.values
        .firstWhere((e) => e.toString().split('.').last == json['indicators']);
    var length = json['length'];
    var isShow = json['isShow'];
    switch (type) {
      case IndicatorsType.MA:
        return MovingAverage(length, isShow);
      case IndicatorsType.BOLL:
      case IndicatorsType.MACD:
      case IndicatorsType.KDJ:
      case IndicatorsType.RSI:
      case IndicatorsType.WR:
      case IndicatorsType.CCI:
      default:
        throw Exception('Unknown indicator type: $type');
    }
  }
}

IndicatorsType mapStringToEnum(String indicator) {
  switch (indicator) {
    case 'Moving Average':
      return IndicatorsType.MA;
    case 'MACD':
      return IndicatorsType.MACD;
    case 'RSI':
      return IndicatorsType.RSI;
    case 'Bollinger Bands':
      return IndicatorsType.BOLL;
    case 'Stochastic Oscillator':
      return IndicatorsType.KDJ;
    case 'CCI':
      return IndicatorsType.CCI;
    case 'WR':
      return IndicatorsType.WR;
    case 'KDJ':
      return IndicatorsType.KDJ;
    default:
      throw Exception('Unknown indicator: $indicator');
  }
}
