import 'package:flutter/material.dart';
import 'package:interactive_chart/src/ui/rounded_text_button.dart';
import '../indicators/indicators.dart';
import 'rounded_icon_button.dart';
import 'stock_indicator_dialog.dart';

class TopToolWindow extends StatefulWidget {
  final Function(IndicatorsType) onIndicatorSelected;
  final Function(String) onTimeFrameSelected;
  final String minimumTimeframe;
  final String title;

  TopToolWindow(
      {super.key,
      required this.title,
      required this.onIndicatorSelected,
      required this.onTimeFrameSelected,
      this.minimumTimeframe = "1 day"});

  @override
  State<TopToolWindow> createState() => _TopToolWindowState();
}

class _TopToolWindowState extends State<TopToolWindow> {
  String? selectedTimeframe;

  final List<String> timeframes = [
    '1 minute',
    '2 minutes',
    '3 minutes',
    '4 minutes',
    '5 minutes',
    '10 minutes',
    '15 minutes',
    '30 minutes',
    '1 hour',
    '2 hours',
    '3 hours',
    '1 day',
    '1 week',
    '1 month'
  ];

  @override
  void initState() {
    super.initState();
    selectedTimeframe = widget.minimumTimeframe;
  }

  List<DropdownMenuItem<String>> _buildDropdownItems() {
    List<DropdownMenuItem<String>> items = [];
    final minIndex = timeframes.indexOf(widget.minimumTimeframe);

    // Minutes section
    final minuteItems = timeframes
        .where((t) => t.contains('minute'))
        .where((t) => timeframes.indexOf(t) >= minIndex);

    if (minuteItems.isNotEmpty) {
      items.add(DropdownMenuItem<String>(
        value: 'minute',
        child: Text('Minute', style: TextStyle(fontWeight: FontWeight.bold)),
        enabled: false,
      ));
      items.addAll(minuteItems.map((t) => DropdownMenuItem<String>(
            value: t,
            child: Text(t),
          )));
      items.add(DropdownMenuItem<String>(
        value: 'separator1',
        enabled: false,
        child: Divider(height: 1),
      ));
    }

    // Hours section
    final hourItems = timeframes
        .where((t) => t.contains('hour'))
        .where((t) => timeframes.indexOf(t) >= minIndex);

    if (hourItems.isNotEmpty) {
      items.add(DropdownMenuItem<String>(
        value: 'hour',
        child: Text('Hour', style: TextStyle(fontWeight: FontWeight.bold)),
        enabled: false,
      ));
      items.addAll(hourItems.map((t) => DropdownMenuItem<String>(
            value: t,
            child: Text(t),
          )));
      items.add(DropdownMenuItem<String>(
        value: 'separator2',
        enabled: false,
        child: Divider(height: 1),
      ));
    }

    // Days/Weeks/Months section
    final dayItems = timeframes
        .where((t) =>
            t.contains('day') || t.contains('week') || t.contains('month'))
        .where((t) => timeframes.indexOf(t) >= minIndex);

    if (dayItems.isNotEmpty) {
      items.add(DropdownMenuItem<String>(
        value: 'day',
        child: Text('Day', style: TextStyle(fontWeight: FontWeight.bold)),
        enabled: false,
      ));
      items.addAll(dayItems.map((t) => DropdownMenuItem<String>(
            value: t,
            child: Text(t),
          )));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 10),
      child: Row(
        children: [
          Text(widget.title),
          getDivider(),
          DropdownButton<String>(
            value: selectedTimeframe,
            items: _buildDropdownItems(),
            onChanged: (value) {
              setState(() {
                selectedTimeframe = value;
                widget.onTimeFrameSelected(selectedTimeframe!);
              });
            },
            underline: Container(),
            focusColor: Colors.transparent,
            focusNode: FocusNode(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          getDivider(),
          RoundedIconButton(
            icon: Icons.addchart,
            onPressed: _showStockIndicatorDialog,
            size: 25,
          ),
          getDivider(),
        ],
      ),
    );
  }

  Widget getDivider() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: VerticalDivider(
        // color: colorScheme.onSurface,
        thickness: 1,
        width: 5,
      ),
    );
  }

  void _showStockIndicatorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StockIndicatorDialog(
          onIndicatorSelected: widget.onIndicatorSelected,
        );
      },
    );
  }
}
