import 'package:flutter/material.dart';

import '../indicators/indicators.dart';

class StockIndicatorDialog extends StatefulWidget {
  final Function(IndicatorsType) onIndicatorSelected;

  const StockIndicatorDialog({super.key, required this.onIndicatorSelected});

  @override
  _StockIndicatorDialogState createState() => _StockIndicatorDialogState();
}

class _StockIndicatorDialogState extends State<StockIndicatorDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _indicators = [
    'Moving Average',
    'MACD',
    'RSI',
    'Bollinger Bands',
    'Stochastic Oscillator',
    'CCI',
    'KDJ',
    'WR'
  ];
  List<String> _filteredIndicators = [];

  @override
  void initState() {
    super.initState();
    _filteredIndicators = _indicators;
    _searchController.addListener(_filterIndicators);
  }

  void _filterIndicators() {
    setState(() {
      _filteredIndicators = _indicators
          .where((indicator) => indicator
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  void _selectIndicator(String indicator) {
    widget.onIndicatorSelected(mapStringToEnum(indicator));
    Navigator.of(context).pop(indicator);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 300, // Set the desired width
        height: 400, // Set the desired height
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredIndicators.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_filteredIndicators[index]),
                    onTap: () => _selectIndicator(_filteredIndicators[index]),
                  );
                },
              ),
            ),
            Container(
              height: 20,
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
