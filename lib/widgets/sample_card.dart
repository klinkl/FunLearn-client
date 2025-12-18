import 'package:flutter/material.dart';
import '../screens/learning_view.dart';
import '../theme/customColors.dart';

//temporary
import '../model/flashcard.dart';

final List<Flashcard> flashcards = [
  Flashcard(name: 'addition', front: '2 + 2', back: '4'),
  Flashcard(name: 'english-french', front: 'Hello', back: 'Bonjour'),
];

////////////////////////////////////////////////////////////////////////////////
class SampleCard extends StatelessWidget {
  final String cardName;
  const SampleCard({required this.cardName, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;

    return SizedBox(
      width: 150,
      height: 100,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LearningView(flashcard: flashcards[1]),
            ),
          );
        },
        child: Card(
          color: customColors.card,
          child: Center(
            child: Text(
              cardName,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
