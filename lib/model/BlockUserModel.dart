import 'package:cloud_firestore/cloud_firestore.dart';

class BlockUserModel {
  Timestamp createdAt;

  String dest;

  String source;

  String type;

  BlockUserModel({createdAt, this.dest = '', this.source = '', this.type = ''})
      : this.createdAt = createdAt ?? Timestamp.now();

  factory BlockUserModel.fromJson(Map<String, dynamic> parsedJson) {
    return new BlockUserModel(
        createdAt: parsedJson['createdAt'],
        dest: parsedJson['dest'] ?? '',
        source: parsedJson['source'] ?? '',
        type: parsedJson['type'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': this.createdAt,
      'dest': this.dest,
      'source': this.source,
      'type': this.type
    };
  }
}
