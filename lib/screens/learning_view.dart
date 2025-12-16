import 'package:flutter/material.dart';
import 'package:funlearn_client/data/models/deck.dart';
import 'package:funlearn_client/data/models/flashcard.dart';
class Flashcard {
  final String front;
  final String back;

  Flashcard({required this.front, required this.back});
}

class MyFlashcardScreen extends StatelessWidget {
  const MyFlashcardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Flashcard card = Flashcard(front: "2 + 2", back: "4");
    return LearningView(flashcard: card);
  }
}

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
    return Scaffold(
      appBar: AppBar(title: Text("Flashcard")),

      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 2),
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
                child: Divider(thickness: 1, color: Colors.black),
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
                Expanded(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.1,
                    child: TextButton(
                      onPressed: _show,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      child: Text("Again"),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.1,
                    child: TextButton(
                      onPressed: _show,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      child: Text("Hard"),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.1,
                    child: TextButton(
                      onPressed: _show,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      child: Text("Okay"),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.1,
                    child: TextButton(
                      onPressed: _show,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      child: Text("Easy"),
                    ),
                  ),
                ),
              ],
            )
          : SizedBox(
              height: MediaQuery.of(context).size.height * 0.1,
              width: double.infinity,
              child: TextButton(
                onPressed: _show,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
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
