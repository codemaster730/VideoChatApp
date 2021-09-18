import 'package:cloud_firestore/cloud_firestore.dart';

class MessageData {
  String messageID;

  Url url;

  String content;

  Timestamp created;

  String recipientFirstName;

  String recipientLastName;

  String recipientProfilePictureURL;

  String recipientID;

  String senderFirstName;

  String senderLastName;

  String senderProfilePictureURL;

  String senderID;

  String videoThumbnail;

  MessageData(
      {this.messageID = '',
      url,
      this.content = '',
      created,
      this.recipientFirstName = '',
      this.recipientLastName = '',
      this.recipientProfilePictureURL = '',
      this.recipientID = '',
      this.senderFirstName = '',
      this.senderLastName = '',
      this.senderProfilePictureURL = '',
      this.senderID = '',
      this.videoThumbnail = ''})
      : this.url = url ?? Url(),
        this.created = created ?? Timestamp.now();

  factory MessageData.fromJson(Map<String, dynamic> parsedJson) {
    return new MessageData(
        messageID: parsedJson['id'] ?? parsedJson['messageID'] ?? '',
        url: Url.fromJson(parsedJson['url'] ?? {'mime': '', 'url': ''}),
        content: parsedJson['content'] ?? '',
        created: parsedJson['createdAt'] ?? parsedJson['created'],
        recipientFirstName: parsedJson['recipientFirstName'] ?? '',
        recipientLastName: parsedJson['recipientLastName'] ?? '',
        recipientProfilePictureURL:
            parsedJson['recipientProfilePictureURL'] ?? '',
        recipientID: parsedJson['recipientID'] ?? '',
        senderFirstName: parsedJson['senderFirstName'] ?? '',
        senderLastName: parsedJson['senderLastName'] ?? '',
        senderProfilePictureURL: parsedJson['senderProfilePictureURL'] ?? '',
        senderID: parsedJson['senderID'] ?? '',
        videoThumbnail: parsedJson['videoThumbnail'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': this.messageID,
      'url': this.url.toJson(),
      'content': this.content,
      'createdAt': this.created,
      'recipientFirstName': this.recipientFirstName,
      'recipientLastName': this.recipientLastName,
      'recipientProfilePictureURL': this.recipientProfilePictureURL,
      'recipientID': this.recipientID,
      'senderFirstName': this.senderFirstName,
      'senderLastName': this.senderLastName,
      'senderProfilePictureURL': this.senderProfilePictureURL,
      'senderID': this.senderID,
      'videoThumbnail': this.videoThumbnail
    };
  }
}

class Url {
  String mime;

  String url;

  Url({this.mime = '', this.url = ''});

  factory Url.fromJson(Map<dynamic, dynamic> parsedJson) {
    return new Url(
        mime: parsedJson['mime'] ?? '', url: parsedJson['url'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'mime': this.mime, 'url': this.url};
  }
}
