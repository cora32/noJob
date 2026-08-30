import 'package:flutter/material.dart';
import 'package:nojob/shared/shared.dart';

class Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;

  const Panel({
    super.key,
    required this.title,
    required this.child,
    this.height = 250,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: labelStyle),
            const SizedBox(height: 16),
            Container(
              height: height,
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
