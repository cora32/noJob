import 'dart:math';

import 'package:NoJob/features/title/ui/AppTitleProvider.dart';
import 'package:NoJob/shared/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final themeState = ref.watch(appTitleProvider);

        return themeState.when(
          data: (state) => SizedBox(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "noJob",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        height: 0.8, // Tighter line height
                      ),
                    ),
                    const Text(
                      "(for you)",
                      style: TextStyle(
                        fontWeight: FontWeight.w100,
                        color: Colors.grey,
                        fontSize: 15,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: NoJobThemes.values.map((theme) {
                    final isSelected = state.selectedTheme == theme;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: GestureDetector(
                        onTap: () => ref
                            .read(appTitleProvider.notifier)
                            .selectTheme(theme),
                        child: ColorSelector(
                          colors: [
                            theme.colorTheme.colorBackground,
                            theme.colorTheme.accentColor,
                          ],
                          isSelected: isSelected,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }
}

@Preview()
Widget appTitlePreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Center(child: AppTitle())),
  );
}

class ColorSelector extends StatelessWidget {
  final List<Color> colors;
  final bool isSelected;

  const ColorSelector({
    super.key,
    required this.colors,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(color: Colors.blue, width: 2)
            : Border.all(color: Colors.transparent, width: 2),
      ),
      padding: const EdgeInsets.all(2),
      // Space between border and circle
      child: CustomPaint(painter: ColorSelectorPainter(colors: colors)),
    );
  }
}

class ColorSelectorPainter extends CustomPainter {
  final List<Color> colors;
  late Paint _paint2;

  ColorSelectorPainter({required this.colors}) {
    _paint2 = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill
      ..color = colors[1];
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw background color (full circle)
    final bgPaint = Paint()..color = colors[0];
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      bgPaint,
    );

    // 2. Draw filled arc (half of second color)
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final offset = (45.0).toRad();
    final startAngle = -pi / 2 - offset; // -90 deg; // Top
    const sweepAngle = pi; // Half circle

    canvas.drawArc(rect, startAngle, sweepAngle, true, _paint2);
  }

  @override
  bool shouldRepaint(covariant ColorSelectorPainter oldDelegate) {
    return colors != oldDelegate.colors;
  }
}
