import 'package:flutter/material.dart';

class LeftToolWindow extends StatefulWidget {
  LeftToolWindow({super.key});

  @override
  State<LeftToolWindow> createState() => _LeftToolWindowState();
}

class _LeftToolWindowState extends State<LeftToolWindow> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [],
          ),
          Column(
            children: [],
          ),
        ],
      ),
    );
  }
}
