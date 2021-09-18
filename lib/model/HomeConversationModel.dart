import 'package:instachatty/model/ConversationModel.dart';

import 'User.dart';

class HomeConversationModel {
  bool isGroupChat;

  List<User> members;

  ConversationModel? conversationModel;

  HomeConversationModel(
      {this.isGroupChat = false,
      this.members = const [],
      this.conversationModel});
}
