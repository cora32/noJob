import 'package:flutter/material.dart';

class HorizontalLineLabel extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final Color? color;
  final double thickness;
  final double indent;
  final double endIndent;

  const HorizontalLineLabel({
    super.key,
    required this.text,
    this.textStyle,
    this.color,
    this.thickness = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: color ?? Colors.grey.withValues(alpha: 0.3),
              thickness: thickness,
              indent: indent,
              endIndent: 16,
            ),
          ),
          Text(
            text,
            style:
                textStyle ??
                const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey,
                ),
          ),
          Expanded(
            child: Divider(
              color: color ?? Colors.grey.withValues(alpha: 0.3),
              thickness: thickness,
              indent: 16,
              endIndent: endIndent,
            ),
          ),
        ],
      ),
    );
  }
}
