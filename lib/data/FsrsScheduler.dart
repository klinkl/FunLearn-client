import 'package:fsrs/fsrs.dart';

void main(){
  var scheduler = Scheduler();
  var card = Card(cardId: 1);
  var reviewLog;
  final rating = Rating.good;
  var cardDict = card.toMap();
  print(cardDict);
  scheduler.reviewCard(card, rating);
  cardDict = card.toMap();
  print(cardDict);
  (:card, :reviewLog) = scheduler.reviewCard(card, rating);
  print("Card rated ${reviewLog.rating} at ${reviewLog.reviewDateTime}");
  print(card.toMap());
}
