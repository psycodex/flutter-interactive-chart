import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:interactive_chart/src/entity/entity.dart';
import 'package:interactive_chart/src/util/data_util.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:interactive_chart/src/ui/top_tool_window.dart';

import 'constants.dart';
import 'entity/info_window_entity.dart';
import 'ui/bottom_tool_window.dart';
import 'entity/candle_data.dart';
import 'chart_painter.dart';
import 'chart_style.dart';
import 'indicators/indicators.dart';
import 'painter_params.dart';
import 'ui/info_widget.dart';
import 'util/number_util.dart';

class InteractiveChart extends StatefulWidget {
  final Entity entity;

  /// The default number of data points to be displayed when the chart is first
  /// opened. The default value is 90. If [CandleData] does not have enough data
  /// points, the chart will display all of them.
  final int initialVisibleCandleCount;

  /// If non-null, the style to use for this chart.
  final ChartStyle style;

  /// How the date/time label at the bottom are displayed.
  ///
  /// If null, it defaults to use yyyy-mm format if more than 20 data points
  /// are visible in the current chart window, otherwise it uses mm-dd format.
  final TimeLabelGetter? timeLabel;

  /// How the price labels on the right are displayed.
  ///
  /// If null, it defaults to show 2 digits after the decimal point.
  final PriceLabelGetter? priceLabel;

  /// How the overlay info are displayed, when user touches the chart.
  ///
  /// If null, it defaults to display `date`, `open`, `high`, `low`, `close`
  /// and `volume` fields when user selects a data point in the chart.
  ///
  /// To customize it, pass in a function that returns a Map<String,String>:
  /// ```dart
  /// return {
  ///   "Date": "Customized date string goes here",
  ///   "Open": candle.open?.toStringAsFixed(2) ?? "-",
  ///   "Close": candle.close?.toStringAsFixed(2) ?? "-",
  /// };
  /// ```
  final OverlayInfoGetter? overlayInfo;

  /// An optional event, fired when the user clicks on a candlestick.
  final ValueChanged<CandleData>? onTap;

  /// An optional event, fired when user zooms in/out.
  ///
  /// This provides the width of a candlestick at the current zoom level.
  final ValueChanged<double>? onCandleResize;
  final Function(String) onTimeFrameSelected;
  final String minimumTimeframe;

  InteractiveChart({
    Key? key,
    required this.entity,
    required this.onTimeFrameSelected,
    this.initialVisibleCandleCount = 90,
    ChartStyle? style,
    this.timeLabel,
    this.priceLabel,
    this.overlayInfo,
    this.onTap,
    this.onCandleResize,
    this.minimumTimeframe = "1 day",
  })
      : this.style = style ?? const ChartStyle(),
        assert(entity.candles.length >= 3,
        "InteractiveChart requires 3 or more CandleData"),
        assert(initialVisibleCandleCount >= 3,
        "initialVisibleCandleCount must be more 3 or more"),
        super(key: key);

  @override
  _InteractiveChartState createState() => _InteractiveChartState();
}

class _InteractiveChartState extends State<InteractiveChart> {
  // The width of an individual bar in the chart.
  late double _candleWidth;

  // The x offset (in px) of current visible chart window,
  // measured against the beginning of the chart.
  // i.e. a value of 0.0 means we are displaying data for the very first day,
  // and a value of 20 * _candleWidth would be skipping the first 20 days.
  late double _startOffset;

  // The position that user is currently tapping, null if user let go.
  Offset? _tapPosition;

  double? _prevChartWidth; // used by _handleResize
  late double _prevCandleWidth;
  late double _prevStartOffset;
  late Offset _initialFocalPoint;
  PainterParams? _prevParams; // used in onTapUp event
  double _topToolWindowHeight = 40;
  double _bottomToolWindowHeight = 30;

  String? previousTitle;
  String? previousTimeFrame;
  TimeUnit defaultTimeUnit = TimeUnit.seconds;
  Duration durationDiff = Duration.zero;
  final StreamController<InfoWindowEntity?> mInfoWindowStream =
  StreamController<InfoWindowEntity?>();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    if (widget.entity.timeFrame == null) {
      widget.entity.timeFrame = widget.minimumTimeframe;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (previousTitle != widget.entity.title) {
      _loadPreferences();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final size = constraints.biggest;
        final w = size.width - widget.style.priceLabelWidth;
        _handleResize(w);
        // print(
        //     "time frame: ${widget.entity
        //         .timeFrame}, previous time frame: $previousTimeFrame");
        // if (widget.entity.timeFrame == null) {
        //   print("null");
        // }
        previousTitle = widget.entity.title;
        previousTimeFrame = widget.entity.timeFrame;

        durationDiff = getTimeDifferences(widget.entity.candles);

        // Find the visible data range
        final int start = (_startOffset / _candleWidth).floor();
        final int count = (w / _candleWidth).ceil();
        final int end =
        (start + count).clamp(start, widget.entity.candles.length);
        final candlesInRange =
        widget.entity.candles.getRange(start, end).toList();
        if (end < widget.entity.candles.length) {
          // Put in an extra item, since it can become visible when scrolling
          final nextItem = widget.entity.candles[end];
          candlesInRange.add(nextItem);
        }

        // If possible, find neighbouring trend line data,
        // so the chart could draw better-connected lines
        final leadingTrends = widget.entity.candles
            .at(start - 1)
            ?.maLines;
        final trailingTrends = widget.entity.candles
            .at(end + 1)
            ?.maLines;

        // Find the horizontal shift needed when drawing the candles.
        // First, always shift the chart by half a candle, because when we
        // draw a line using a thick paint, it spreads to both sides.
        // Then, we find out how much "fraction" of a candle is visible, since
        // when users scroll, they don't always stop at exact intervals.
        final halfCandle = _candleWidth / 2;
        final fractionCandle = _startOffset - start * _candleWidth;
        final xShift = halfCandle - fractionCandle;

        // Calculate min and max among the visible data
        double? highest(CandleData c) {
          return c.high;
        }

        double? lowest(CandleData c) {
          return c.low;
        }

        final maxPrice =
        candlesInRange.map(highest).whereType<double>().reduce(max);
        final minPrice =
        candlesInRange.map(lowest).whereType<double>().reduce(min);
        final maxVol = candlesInRange
            .map((c) => c.volume)
            .whereType<double>()
            .fold(double.negativeInfinity, max);
        final minVol = candlesInRange
            .map((c) => c.volume)
            .whereType<double>()
            .fold(double.infinity, min);

        final child = TweenAnimationBuilder(
          tween: PainterParamsTween(
            end: PainterParams(
                candles: candlesInRange,
                style: widget.style,
                size: Size(
                    size.width,
                    size.height -
                        _topToolWindowHeight -
                        _bottomToolWindowHeight),
                candleWidth: _candleWidth,
                startOffset: _startOffset,
                maxPrice: maxPrice,
                minPrice: minPrice,
                maxVol: maxVol,
                minVol: minVol,
                xShift: xShift,
                tapPosition: _tapPosition,
                leadingTrends: leadingTrends,
                trailingTrends: trailingTrends,
                sink: mInfoWindowStream.sink),
          ),
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (_, PainterParams params, __) {
            _prevParams = params;
            return RepaintBoundary(
              child: CustomPaint(
                size: Size(
                    size.width,
                    size.height -
                        _topToolWindowHeight -
                        _bottomToolWindowHeight),
                painter: ChartPainter(
                  params: params,
                  getTimeLabel: widget.timeLabel ?? defaultTimeLabel,
                  getPriceLabel: widget.priceLabel ?? defaultPriceLabel,
                  getOverlayInfo: widget.overlayInfo ?? defaultOverlayInfo,
                ),
              ),
            );
          },
        );

        Color dividerColor = Theme
            .of(context)
            .dividerColor;
        const double windowBorderSize = 1;
        return Column(
          children: [
            // Top tool window
            Container(
              height: _topToolWindowHeight,
              decoration: BoxDecoration(
                border: Border(
                  bottom:
                  BorderSide(color: dividerColor, width: windowBorderSize),
                ),
              ),
              child: TopToolWindow(
                title: widget.entity.title,
                onIndicatorSelected: _onIndicatorSelected,
                onTimeFrameSelected: (timeFrame) {
                  // print(
                  //     "time frame changed to $timeFrame, previous time frame: ${widget
                  //         .entity.timeFrame}");
                  // setState(() {
                  // previousTimeFrame = widget.entity.timeFrame;
                  widget.entity.timeFrame = timeFrame;
                  widget.onTimeFrameSelected(timeFrame);
                  // });
                },
                minimumTimeframe: widget.minimumTimeframe,
              ),
            ),
            Row(
              children: [
                // Left tool window
                // Container(
                //   width: 50.0,
                //   decoration: BoxDecoration(
                //     border: Border(
                //       right: BorderSide(color: dividerColor, width: windowBorderSize),
                //     ),
                //   ),
                //   child: LeftToolWindow(),
                // ),
                MouseRegion(
                  onHover: (event) =>
                      setState(() {
                        _tapPosition = event.localPosition;
                      }),
                  onExit: (event) =>
                      setState(() {
                        _tapPosition = null;
                      }),
                  child: Listener(
                    onPointerCancel: (event) =>
                        setState(() {
                          _tapPosition = null;
                        }),
                    onPointerSignal: (signal) {
                      if (signal is PointerScrollEvent) {
                        final dy = signal.scrollDelta.dy;
                        if (dy.abs() > 0) {
                          _onScaleStart(signal.position);
                          _onScaleUpdate(
                            dy > 0 ? 0.9 : 1.1,
                            signal.position,
                            w,
                          );
                        }
                      }
                    },
                    child: GestureDetector(
                      // Tap and hold to view candle details
                      onTapDown: (details) =>
                          setState(() {
                            _tapPosition = details.localPosition;
                          }),
                      onTapCancel: () => setState(() => _tapPosition = null),
                      onTapUp: (_) {
                        // Fire callback event and reset _tapPosition
                        if (widget.onTap != null) _fireOnTapEvent();
                        setState(() => _tapPosition = null);
                      },
                      // Pan and zoom
                      onScaleStart: (details) =>
                          _onScaleStart(details.localFocalPoint),
                      onScaleUpdate: (details) =>
                          _onScaleUpdate(
                              details.scale, details.localFocalPoint, w),
                      child: Stack(children: [
                        child,
                        _buildDefaultInfo(),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
            // Bottom tool window
            Container(
              height: 30.0,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: dividerColor, width: windowBorderSize),
                ),
              ),
              child: BottomToolWindow(),
            ),
          ],
        );
      },
    );
  }

  dispose() {
    mInfoWindowStream.sink.close();
    mInfoWindowStream.close();
    super.dispose();
  }

  Widget _buildDefaultInfo() {
    return StreamBuilder(
        stream: mInfoWindowStream.stream,
        builder: (context, snapshot) {
          CandleData? candle;
          CandleData? previousCandle;
          if (snapshot.hasData) {
            candle = snapshot.data?.candle;
            previousCandle = snapshot.data?.previousCandle;
          }
          if (candle == null) {
            candle = widget.entity.candles[widget.entity.candles.length - 1];
            if (widget.entity.candles.length - 2 > 0) {
              previousCandle =
              widget.entity.candles[widget.entity.candles.length - 2];
            }
          }
          double change = candle.close - candle.open;
          double changePercent = change / candle.open * 100;
          if (previousCandle != null) {
            change = candle.close - previousCandle.close;
            changePercent = (change / previousCandle.close) * 100;
          }
          final infos = [
            "O: ${candle.open.toStringAsFixed(fixedLength)}",
            "H: ${candle.high.toStringAsFixed(fixedLength)}",
            "L: ${candle.low.toStringAsFixed(fixedLength)}",
            "C: ${candle.close.toStringAsFixed(fixedLength)}",
            "Change: ${changePercent.toStringAsFixed(fixedLength)}%",
          ];
          Color valueColor = changePercent >= 0 ? Colors.green : Colors.red;
          List<Widget> infoWidget = [
            Text(
              widget.entity.title,
              style: TextStyle(fontSize: 12.0, decoration: TextDecoration.none),
            ),
            Text("  "),
          ];
          infoWidget.addAll(infos.map((info) {
            return Row(
              children: [
                Text(
                  info.split(":")[0] + ": ",
                  style: TextStyle(
                      fontSize: 10.0, decoration: TextDecoration.none),
                ),
                Text(
                  info.split(":")[1],
                  style: TextStyle(
                      color: valueColor,
                      fontSize: 10.0,
                      decoration: TextDecoration.none),
                ),
                SizedBox(width: 4),
              ],
            );
          }).toList());
          return Positioned(
            left: 10,
            top: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: infoWidget,
                ),
                if (candle.volume! > 0) ...[
                  SizedBox(height: 4),
                  InfoWidget(
                    title: "Volume: ",
                    child: Row(
                      children: [
                        Text(
                          "${NumberUtil.format(candle.volume!)}",
                          style: TextStyle(
                              color: valueColor,
                              fontSize: 10.0,
                              decoration: TextDecoration.none),
                        ),
                      ],
                    ),
                    toggleVisibility: _toggleVolumeVisibility,
                    showCloseIcon: false,
                  ),
                ],
                ..._buildSecondaryInfo(candle),
              ],
            ),
          );
        });
  }

  List<Widget> _buildSecondaryInfo(CandleData? entity) {
    return widget.entity.indicators.map((indicator) {
      return InfoWidget(
        title: indicator.indicatorType
            .toString()
            .split('.')
            .last +
            " " +
            indicator.length.toString() +
            ": ",
        length: indicator.length,
        child: Row(
          children: [
            Text(
              entity?.maLines[indicator.length]?.toStringAsFixed(fixedLength) ??
                  '',
              style: TextStyle(fontSize: 10.0, decoration: TextDecoration.none),
            ),
          ],
        ),
        closeCallback: () =>
            setState(() {
              widget.entity.indicators1.remove(indicator);
              for (int i = 0; i < widget.entity.candles.length; i++) {
                widget.entity.candles[i].maLines.remove(indicator.length);
              }
              CandleData.forceUpdate = true;
              _savePreferences();
            }),
        saveCallback: (int length, int? previousLength) {
          if (length == previousLength) {
            return;
          }
          setState(() {
            for (int i = 0; i < widget.entity.candles.length; i++) {
              widget.entity.candles[i].maLines.remove(previousLength);
            }
            indicator.length = length;

            DataUtil.calculate(widget.entity.candles, [indicator.length]);
            CandleData.forceUpdate = true;
          });
          _savePreferences();
        },
      );
    }).toList();
  }

  void _toggleVolumeVisibility() {
    setState(() {
      // volHidden = !volHidden;
    });
  }

  void _onIndicatorSelected(IndicatorsType indicatorType) {
    setState(() {
      widget.entity.indicators
          .add(Indicators(IndicatorsType.MA, defaultMovingAverage, true));

      DataUtil.calculate(widget.entity.candles, [defaultMovingAverage]);
    });
    CandleData.forceUpdate = true;
    _savePreferences();
  }

  _onScaleStart(Offset focalPoint) {
    _prevCandleWidth = _candleWidth;
    _prevStartOffset = _startOffset;
    _initialFocalPoint = focalPoint;
  }

  _onScaleUpdate(double scale, Offset focalPoint, double w) {
    // Handle zoom
    final candleWidth = (_prevCandleWidth * scale)
        .clamp(_getMinCandleWidth(w), _getMaxCandleWidth(w));
    final clampedScale = candleWidth / _prevCandleWidth;
    var startOffset = _prevStartOffset * clampedScale;
    // Handle pan
    final dx = (focalPoint - _initialFocalPoint).dx * -1;
    startOffset += dx;
    // Adjust pan when zooming
    final double prevCount = w / _prevCandleWidth;
    final double currCount = w / candleWidth;
    final zoomAdjustment = (currCount - prevCount) * candleWidth;
    final focalPointFactor = focalPoint.dx / w;
    startOffset -= zoomAdjustment * focalPointFactor;
    startOffset = startOffset.clamp(0, _getMaxStartOffset(w, candleWidth));
    // Fire candle width resize event
    if (candleWidth != _candleWidth) {
      widget.onCandleResize?.call(candleWidth);
    }
    // Apply changes
    setState(() {
      _candleWidth = candleWidth;
      _startOffset = startOffset;
    });
  }

  _handleResize(double w) {
    if (w == _prevChartWidth &&
        widget.entity.title == previousTitle &&
        widget.entity.timeFrame == previousTimeFrame) return;
    // if (false &&_prevChartWidth != null) {
    //   // Re-clamp when size changes (e.g. screen rotation)
    //   _candleWidth = _candleWidth.clamp(
    //     _getMinCandleWidth(w),
    //     _getMaxCandleWidth(w),
    //   );
    //   _startOffset = _startOffset.clamp(
    //     0,
    //     _getMaxStartOffset(w, _candleWidth),
    //   );
    // } else {
    // Default zoom level. Defaults to a 90 day chart, but configurable.
    // If data is shorter, we use the whole range.
    final count = min(
      widget.entity.candles.length,
      widget.initialVisibleCandleCount,
    );
    _candleWidth = w / count;
    // Default show the latest available data, e.g. the most recent 90 days.
    _startOffset = (widget.entity.candles.length - count) * _candleWidth;
    // }
    _prevChartWidth = w;
  }

  // The narrowest candle width, i.e. when drawing all available data points.
  double _getMinCandleWidth(double w) => w / widget.entity.candles.length;

  // The widest candle width, e.g. when drawing 14 day chart
  double _getMaxCandleWidth(double w) =>
      w / min(14, widget.entity.candles.length);

  // Max start offset: how far can we scroll towards the end of the chart
  double _getMaxStartOffset(double w, double candleWidth) {
    final count = w / candleWidth; // visible candles in the window
    final start = widget.entity.candles.length - count;
    return max(0, candleWidth * start);
  }

  String defaultTimeLabel(int timestamp, int visibleDataCount) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final totalDuration = durationDiff * visibleDataCount;

    if (totalDuration.inDays >= 365) {
      return DateFormat.yMMM().format(date);
    } else if (totalDuration.inDays >= 1) {
      return DateFormat.MMMd().format(date);
    } else {
      return DateFormat.d().format(date);
    }
  }

  String defaultPriceLabel(double price) => price.toStringAsFixed(2);

  Map<String, String> defaultOverlayInfo(CandleData candle) {
    final date = DateFormat.yMMMd()
        .format(DateTime.fromMillisecondsSinceEpoch(candle.timestamp));
    return {
      "Date": date,
      "Open": candle.open.toStringAsFixed(2),
      "High": candle.high.toStringAsFixed(2),
      "Low": candle.low.toStringAsFixed(2),
      "Close": candle.close.toStringAsFixed(2),
      "Volume": candle.volume?.asAbbreviated() ?? "-",
    };
  }

  void _fireOnTapEvent() {
    if (_prevParams == null || _tapPosition == null) return;
    final params = _prevParams!;
    final dx = _tapPosition!.dx;
    final selected = params.getCandleIndexFromOffset(dx);
    final candle = params.candles[selected];
    widget.onTap?.call(candle);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final indicatorsString = prefs.getString(KeyIndicators);
      if (indicatorsString != null) {
        final List<dynamic> jsonList = jsonDecode(indicatorsString);
        widget.entity.indicators =
            jsonList.map((json) => Indicators.fromJson(json)).toList();
      } else {
        widget.entity.indicators = [];
      }
    });
    setState(() {
      for (Indicators indicator in widget.entity.indicators) {
        DataUtil.calculate(widget.entity.candles, [indicator.length]);
      }
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final indicatorsString =
    jsonEncode(widget.entity.indicators.map((i) => i.toJson()).toList());
    prefs.setString(KeyIndicators, indicatorsString);
  }

  Duration getTimeDifferences(List<CandleData> candles) {
    if (candles.length < 2) return Duration.zero;

    int difference = candles[1].timestamp - candles[0].timestamp;
    Duration duration = Duration(milliseconds: difference);
    //
    // int years = duration.inDays ~/ 365;
    // int months = (duration.inDays % 365) ~/ 30;
    // int days = (duration.inDays % 365) % 30;
    // int hours = duration.inHours % 24;
    // int minutes = duration.inMinutes % 60;
    // int seconds = duration.inSeconds % 60;
    //
    // if (years > 0) {
    //   return TimeUnit.years;
    // } else if (months > 0) {
    //   return TimeUnit.months;
    // } else if (days > 0) {
    //   return TimeUnit.days;
    // } else if (hours > 0) {
    //   return TimeUnit.hours;
    // } else if (minutes > 0) {
    //   return TimeUnit.minutes;
    // } else if (seconds > 0) {
    //   return TimeUnit.seconds;
    // }
    // return TimeUnit.seconds,
    return duration;
  }
}

extension Formatting on double {
  String asPercent() {
    final format = this < 100 ? "##0.00" : "#,###";
    final v = NumberFormat(format, "en_US").format(this);
    return "${this >= 0 ? '+' : ''}$v%";
  }

  String asAbbreviated() {
    if (this < 1000) return this.toStringAsFixed(3);
    if (this >= 1e18) return this.toStringAsExponential(3);
    final s = NumberFormat("#,###", "en_US").format(this).split(",");
    const suffixes = ["K", "M", "B", "T", "Q"];
    return "${s[0]}.${s[1]}${suffixes[s.length - 2]}";
  }
}
