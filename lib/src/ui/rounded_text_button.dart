import 'package:flutter/material.dart';

class RoundedTextButton extends StatelessWidget {
  final Text text;
  final double size;
  final double borderRadius;
  final Color iconColor;
  final bool background;
  final EdgeInsetsGeometry? margin;

  final VoidCallback? onPressed;

  const RoundedTextButton({
    super.key,
    required this.text,
    this.background = false,
    this.size = 40.0,
    this.borderRadius = 7.0,
    this.margin,
    this.iconColor = Colors.grey,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(1.0), // Adjust padding as needed
      // width: size,
      // height: size,
      decoration: background
          ? BoxDecoration(
              color: colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(borderRadius))
          : null,
      margin: margin,
      child: TextButton(
        child: text,
        onPressed: onPressed,
      ),
    );
  }
}
