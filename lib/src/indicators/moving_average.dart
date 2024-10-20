import 'indicators.dart';

class MovingAverage extends Indicators {
  final IndicatorsType indicators = IndicatorsType.MA;

  MovingAverage(int length, bool isShow)
      : super(IndicatorsType.MA, length, isShow);
}
