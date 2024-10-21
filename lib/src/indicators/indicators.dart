enum IndicatorsType { MA, BOLL, MACD, KDJ, RSI, WR, CCI }

class Indicators {
  final IndicatorsType indicatorType;
  final bool isShow;
  int length;

  Indicators(this.indicatorType, this.length, this.isShow);

  Map<String, dynamic> toJson() => {
        'indicators': indicatorType.toString().split('.').last,
        'isShow': isShow,
        'length': length,
      };

  static Indicators fromJson(Map<String, dynamic> json) {
    final type = IndicatorsType.values
        .firstWhere((e) => e.toString().split('.').last == json['indicators']);
    var length = json['length'];
    var isShow = json['isShow'];
    return Indicators(type, length, isShow);
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
