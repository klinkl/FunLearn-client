import 'package:flutter/material.dart';
import '../theme/customColors.dart';

class ProgressBar extends StatelessWidget {
  final double progress; //between 0.0 and 1.0
  final String text;

  const ProgressBar({super.key, required this.progress, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;

    return Container(
      height: 24,
      width: MediaQuery.of(context).size.width * 0.5,
      decoration: BoxDecoration(
        color: customColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: customColors.navigationBar,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Center(
            child: Text(
              text,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
