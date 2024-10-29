import 'package:flutter/material.dart';

class Indicator {
  final String name;
  final IndicatorType type;
  final bool isOverlay;
  final Map<int, double?> values;
  final Color color;

  Indicator(
      {required this.name,
      required this.isOverlay,
      required this.values,
      required this.color,
      required this.type});
}

enum IndicatorType {
  movingAverage,
  relativeStrengthIndex,
}
