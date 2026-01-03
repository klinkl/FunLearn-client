import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/customColors.dart';
import './progress_bar.dart';
class Quest extends StatelessWidget {
  final int rarity;
  final String quest;
  final int value;
  final int requestedValue;
  final bool finished;
  final DateTime expiryDate;
  const Quest({
    super.key,
    required this.rarity,
    required this.quest,
    required this.value,
    required this.requestedValue,
    required this.finished,
    required this.expiryDate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (finished)
            Image.asset('assets/images/open$rarity.png', width: 50, height: 50)
          else
            Image.asset(
              'assets/images/close$rarity.png',
              width: 50,
              height: 50,
            ),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(
                quest,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              ProgressBar(
                progress: value / requestedValue,
                text: '$value / $requestedValue',
              ),
              const SizedBox(height: 4),
              Text(
                'Expires ${_formatExpiry(expiryDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  String _formatExpiry(DateTime expiryDate) {
    return DateFormat('d MMM, HH:mm').format(expiryDate.toLocal());
  }
}
