import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instachatty/constants.dart';
import 'package:instachatty/main.dart';
import 'package:instachatty/model/ConversationModel.dart';
import 'package:instachatty/model/HomeConversationModel.dart';
import 'package:instachatty/model/User.dart';
import 'package:instachatty/services/FirebaseHelper.dart';
import 'package:instachatty/services/helper.dart';
import 'package:instachatty/ui/contacts/ContactsScreen.dart';
import 'package:instachatty/ui/conversations/ConversationsScreen.dart';
import 'package:instachatty/ui/createGroup/CreateGroupScreen.dart';
import 'package:instachatty/ui/profile/ProfileScreen.dart';
import 'package:instachatty/ui/search/SearchScreen.dart';
import 'package:instachatty/ui/videoCall/VideoCallScreen.dart';
import 'package:instachatty/ui/videoCallsGroupChat/VideoCallsGroupScreen.dart';
import 'package:instachatty/ui/voiceCall/VoiceCallScreen.dart';
import 'package:instachatty/ui/voiceCallsGroupChat/VoiceCallsGroupScreen.dart';
import 'package:provider/provider.dart';

enum DrawerSelection { Conversations, Contacts, Search, Profile }

class HomeScreen extends StatefulWidget {
  final User user;
  static bool onGoingCall = false;

  HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  _HomeState createState() {
    return _HomeState();
  }
}

class _HomeState extends State<HomeScreen> {
  late User user;
  DrawerSelection _drawerSelection = DrawerSelection.Conversations;
  String _appBarTitle = tr('conversations');

  late Widget _currentWidget;

  @override
  void initState() {
    super.initState();
    user = widget.user;
    _currentWidget = ConversationsScreen(
      user: user,
    );
    if (CALLS_ENABLED) _listenForCalls();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: user,
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              Consumer<User>(
                builder: (context, user, _) {
                  return DrawerHeader(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        displayCircleImage(user.profilePictureURL, 75, false),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            user.fullName(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              user.email,
                              style: TextStyle(color: Colors.white),
                            )),
                      ],
                    ),
                    decoration: BoxDecoration(
                      color: Color(COLOR_PRIMARY),
                    ),
                  );
                },
              ),
              ListTile(
                selected: _drawerSelection == DrawerSelection.Conversations,
                title: Text('conversations').tr(),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _drawerSelection = DrawerSelection.Conversations;
                    _appBarTitle = 'conversations'.tr();
                    _currentWidget = ConversationsScreen(
                      user: user,
                    );
                  });
                },
                leading: Icon(Icons.chat_bubble),
              ),
              ListTile(
                  selected: _drawerSelection == DrawerSelection.Contacts,
                  leading: Icon(Icons.contacts),
                  title: Text('contacts').tr(),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _drawerSelection = DrawerSelection.Contacts;
                      _appBarTitle = 'contacts'.tr();
                      _currentWidget = ContactsScreen(
                        user: user,
                      );
                    });
                  }),
              ListTile(
                  selected: _drawerSelection == DrawerSelection.Search,
                  title: Text('search').tr(),
                  leading: Icon(Icons.search),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _drawerSelection = DrawerSelection.Search;
                      _appBarTitle = 'search'.tr();
                      _currentWidget = SearchScreen(
                        user: user,
                      );
                    });
                  }),
              ListTile(
                selected: _drawerSelection == DrawerSelection.Profile,
                leading: Icon(Icons.account_circle),
                title: Text('profile').tr(),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _drawerSelection = DrawerSelection.Profile;
                    _appBarTitle = 'profile'.tr();
                    _currentWidget = ProfileScreen(
                      user: user,
                    );
                  });
                },
              ),
            ],
          ),
        ),
        appBar: AppBar(
          title: Text(
            _appBarTitle,
            style: TextStyle(
                color:
                    isDarkMode(context) ? Colors.grey.shade200 : Colors.white,
                fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            _appBarTitle == 'conversations'.tr()
                ? IconButton(
              icon: Icon(Icons.message),
              onPressed: () {
                push(context, CreateGroupScreen());
              },
              color: isDarkMode(context)
                  ? Colors.grey.shade200
                  : Colors.white,
                  )
                : Container(
                    height: 0,
                    width: 0,
                  )
          ],
          iconTheme: IconThemeData(
              color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white),
          backgroundColor: Color(COLOR_PRIMARY),
          centerTitle: true,
        ),
        body: _currentWidget,
      ),
    );
  }

  void _listenForCalls() {
    Stream callStream = FireStoreUtils.firestore
        .collection(USERS)
        .doc(user.userID)
        .collection(CALL_DATA)
        .snapshots();
    // ignore: cancel_subscriptions
    final callSubscription = callStream.listen((event) async {
      if (event.docs.isNotEmpty) {
        DocumentSnapshot callDocument = event.docs.first;
        if (callDocument.id != user.userID) {
          DocumentSnapshot userSnapShot = await FireStoreUtils.firestore
              .collection(USERS)
              .doc(event.docs.first.id)
              .get();
          User caller = User.fromJson(userSnapShot.data() ?? {});
          print('${caller.fullName()} called you');
          print('${callDocument.data()?['type'] ?? 'null'}');
          String type = callDocument.data()?['type'] ?? '';
          bool isGroupCall = callDocument.data()?['isGroupCall'] ?? false;
          String callType = callDocument.data()?['callType'] ?? '';
          Map<String, dynamic> connections =
              callDocument.data()?['connections'] ?? Map<String, dynamic>();
          List<dynamic> groupCallMembers =
              callDocument.data()?['members'] ?? <dynamic>[];
          if (type == 'offer') {
            if (callType == VIDEO) {
              if (isGroupCall) {
                if (!HomeScreen.onGoingCall &&
                    connections.keys.contains(getConnectionID(caller.userID)) &&
                    connections[getConnectionID(caller.userID)]['description']
                            ['type'] ==
                        'offer') {
                  HomeScreen.onGoingCall = true;
                  List<User> members = [];
                  groupCallMembers.forEach((element) {
                    members.add(User.fromJson(element));
                  });
                  push(
                    context,
                    VideoCallsGroupScreen(
                        homeConversationModel: HomeConversationModel(
                            isGroupChat: true,
                            conversationModel: ConversationModel.fromJson(
                                callDocument.data()?['conversationModel']),
                            members: members),
                        isCaller: false,
                        caller: caller,
                        sessionDescription:
                            connections[getConnectionID(caller.userID)]
                                ['description']['sdp'],
                        sessionType: connections[getConnectionID(caller.userID)]
                            ['description']['type']),
                  );
                }
              } else {
                push(
                  context,
                  VideoCallScreen(
                      homeConversationModel: HomeConversationModel(
                          isGroupChat: false,
                          conversationModel: null,
                          members: [caller]),
                      isCaller: false,
                      sessionDescription: callDocument.data()?['data']
                          ['description']['sdp'],
                      sessionType: callDocument.data()?['data']['description']
                          ['type']),
                );
              }
            } else if (callType == VOICE) {
              if (isGroupCall) {
                if (!HomeScreen.onGoingCall &&
                    connections.keys.contains(getConnectionID(caller.userID)) &&
                    connections[getConnectionID(caller.userID)]['description']
                            ['type'] ==
                        'offer') {
                  HomeScreen.onGoingCall = true;
                  List<User> members = [];
                  groupCallMembers.forEach((element) {
                    members.add(User.fromJson(element));
                  });
                  push(
                    context,
                    VoiceCallsGroupScreen(
                        homeConversationModel: HomeConversationModel(
                            isGroupChat: true,
                            conversationModel: ConversationModel.fromJson(
                                callDocument.data()?['conversationModel']),
                            members: members),
                        isCaller: false,
                        caller: caller,
                        sessionDescription:
                            connections[getConnectionID(caller.userID)]
                                ['description']['sdp'],
                        sessionType: connections[getConnectionID(caller.userID)]
                            ['description']['type']),
                  );
                }
              } else {
                push(
                  context,
                  VoiceCallScreen(
                      homeConversationModel: HomeConversationModel(
                          isGroupChat: false,
                          conversationModel: null,
                          members: [caller]),
                      isCaller: false,
                      sessionDescription: callDocument.data()?['data']
                          ['description']['sdp'],
                      sessionType: callDocument.data()?['data']['description']
                          ['type']),
                );
              }
            }
          }
        } else {
          print('you called someone');
        }
      }
    });
    auth.FirebaseAuth.instance.authStateChanges().listen((auth.User? event) {
      if (event == null) {
        callSubscription.cancel();
      }
    });
  }

  String getConnectionID(String friendID) {
    String connectionID;
    String selfID = MyAppState.currentUser!.userID;
    if (friendID.compareTo(selfID) < 0) {
      connectionID = friendID + selfID;
    } else {
      connectionID = selfID + friendID;
    }
    return connectionID;
  }
}
