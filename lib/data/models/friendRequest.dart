import 'package:uuid/uuid.dart';

class FriendRequest {
  String fromUser;
  String toUser;
  bool accepted;

  FriendRequest(this.fromUser, this.toUser, this.accepted);
  Map<String, dynamic> toJson() {
    return {
      'fromUser': fromUser,
      'toUser': toUser,
      'accepted': accepted,
    };
  }
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      json['fromUser'] as String,
      json['toUser'] as String,
      json['accepted'] as bool,
    );
  }
}