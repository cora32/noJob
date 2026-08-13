import 'package:NoJob/shared/extensions.dart';
import 'package:flutter/material.dart';

class InfoPanel extends StatelessWidget {
  final int total;
  final int rejections;
  final int offers;

  const InfoPanel({
    super.key,
    required this.total,
    required this.rejections,
    required this.offers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            children: [
              TextSpan(
                text: '$rejections',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: '\n${context.res.rejections}',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 14),
            children: [
              TextSpan(
                text: '$total',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: '\n${context.res.total}',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
                color: offers == 0 ? Colors.grey : Colors.green, fontSize: 14),
            children: [
              TextSpan(
                text: '$offers',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: '\n${context.res.offers}',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
