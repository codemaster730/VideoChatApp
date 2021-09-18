import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  String id;

  String creatorId;

  String lastMessage;

  String name;

  Timestamp lastMessageDate;

  ConversationModel(
      {this.id = '',
      this.creatorId = '',
      this.lastMessage = '',
      this.name = '',
      lastMessageDate})
      : this.lastMessageDate = lastMessageDate ?? Timestamp.now();

  factory ConversationModel.fromJson(Map<String, dynamic> parsedJson) {
    return new ConversationModel(
        id: parsedJson['id'] ?? '',
        creatorId: parsedJson['creatorID'] ?? parsedJson['creator_id'] ?? '',
        lastMessage: parsedJson['lastMessage'] ?? '',
        name: parsedJson['name'] ?? '',
        lastMessageDate: parsedJson['lastMessageDate']);
  }

  factory ConversationModel.fromPayload(Map<String, dynamic> parsedJson) {
    return new ConversationModel(
        id: parsedJson['id'] ?? '',
        creatorId: parsedJson['creatorID'] ?? parsedJson['creator_id'] ?? '',
        lastMessage: parsedJson['lastMessage'] ?? '',
        name: parsedJson['name'] ?? '',
        lastMessageDate: Timestamp.fromMillisecondsSinceEpoch(
            parsedJson['lastMessageDate']));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': this.id,
      'creatorID': this.creatorId,
      'lastMessage': this.lastMessage,
      'name': this.name,
      'lastMessageDate': this.lastMessageDate
    };
  }

  Map<String, dynamic> toPayload() {
    return {
      "id": this.id,
      "creatorID": this.creatorId,
      "lastMessage": this.lastMessage,
      "name": this.name,
      "lastMessageDate": this.lastMessageDate.millisecondsSinceEpoch
    };
  }
}
