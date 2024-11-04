int fixedLength = 2;

int defaultMovingAverage = 9;

String KeyIndicators = 'indicators';

enum TimeUnit {
  years,
  months,
  days,
  hours,
  minutes,
  seconds,
}

final resample_rules = {
  'T1': '1min',
  'T2': '2min',
  'T3': '3min',
  'T4': '4min',
  'T5': '5min',
  'T10': '10min',
  'T15': '15min',
  'T30': '30min',
  'H1': '1H',
  'H2': '2H',
  'H3': '3H',
  'D': 'D',
  'W': 'W-MON',
  'M': 'M'
};
