import 'package:flutter/material.dart';
import '../theme/customColors.dart';
//temporary
import '../model/flashcard.dart';
////////////////////////////////////////////////////////

class LearningView extends StatefulWidget {
  final Flashcard flashcard;

  const LearningView({super.key, required this.flashcard});

  @override
  State<LearningView> createState() => _LearningViewState();
}

class _LearningViewState extends State<LearningView> {
  bool _backShow = false;

  void _show() {
    setState(() {
      _backShow = !_backShow;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Scaffold(
      appBar: AppBar(title: Text("Flashcard")),

      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: customColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.onPrimary, width: 2),
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    widget.flashcard.front,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),

              Visibility(
                visible: _backShow,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Divider(thickness: 1, color: cs.onPrimary),
              ),

              Expanded(
                child: Visibility(
                  visible: _backShow,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Center(
                    child: Text(
                      widget.flashcard.back,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _backShow
          ? Row(
              children: [
                FlashcardButton(
                  label: 'Again',
                  backgroundColor: Colors.red,
                  onPressed: _show,
                ),
                FlashcardButton(
                  label: 'Hard',
                  backgroundColor: Colors.orange,
                  onPressed: _show,
                ),
                FlashcardButton(
                  label: 'Okay',
                  backgroundColor: Colors.yellow,
                  onPressed: _show,
                ),
                FlashcardButton(
                  label: 'Easy',
                  backgroundColor: Colors.green,
                  onPressed: _show,
                ),
              ],
            )
          : SizedBox(
              height: MediaQuery.of(context).size.height * 0.1,
              width: double.infinity,
              child: TextButton(
                onPressed: _show,
                style: TextButton.styleFrom(
                  backgroundColor: customColors.navigationBar,
                  foregroundColor: cs.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
                child: Text("Show the back"),
              ),
            ),
    );
  }
}

class FlashcardButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const FlashcardButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.1,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: Colors.black,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
