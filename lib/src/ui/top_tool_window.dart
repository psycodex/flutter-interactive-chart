import 'package:flutter/material.dart';
import '../indicators/indicators.dart';
import 'rounded_icon_button.dart';
import 'rounded_text_button.dart';
import 'stock_indicator_dialog.dart';

class TopToolWindow extends StatefulWidget {
  final Function(IndicatorsType) onIndicatorSelected;

  const TopToolWindow({super.key, required this.onIndicatorSelected});

  @override
  State<TopToolWindow> createState() => _TopToolWindowState();
}

class _TopToolWindowState extends State<TopToolWindow> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Colors.blue[100],
      child: Row(
        children: [
          RoundedTextButton(text: Text('D')),
          getDivider(),
          RoundedTextButton(text: Text('W')),
          getDivider(),
          RoundedTextButton(text: Text('M')),
          getDivider(),
          RoundedIconButton(
            icon: Icons.compare_arrows,
            onPressed: _showStockIndicatorDialog,
          ),
          getDivider(),
        ],
      ),
    );
  }

  Widget getDivider() {
    var colorScheme = Theme.of(context).colorScheme;
    return VerticalDivider(
      color: colorScheme.onSurface,
      thickness: 1,
      width: 10,
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
