import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart' as easyLocal;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instachatty/constants.dart';
import 'package:instachatty/main.dart';
import 'package:instachatty/model/ChatModel.dart';
import 'package:instachatty/model/ChatVideoContainer.dart';
import 'package:instachatty/model/ConversationModel.dart';
import 'package:instachatty/model/HomeConversationModel.dart';
import 'package:instachatty/model/MessageData.dart';
import 'package:instachatty/model/User.dart';
import 'package:instachatty/services/FirebaseHelper.dart';
import 'package:instachatty/services/helper.dart';
import 'package:instachatty/ui/chat/PlayerWidget.dart';
import 'package:instachatty/ui/fullScreenImageViewer/FullScreenImageViewer.dart';
import 'package:instachatty/ui/fullScreenVideoViewer/FullScreenVideoViewer.dart';
import 'package:instachatty/ui/videoCall/VideoCallScreen.dart';
import 'package:instachatty/ui/videoCallsGroupChat/VideoCallsGroupScreen.dart';
import 'package:instachatty/ui/voiceCall/VoiceCallScreen.dart';
import 'package:instachatty/ui/voiceCallsGroupChat/VoiceCallsGroupScreen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum RecordingState { HIDDEN, VISIBLE, Recording }

class ChatScreen extends StatefulWidget {
  final HomeConversationModel homeConversationModel;

  const ChatScreen({Key? key, required this.homeConversationModel})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  late HomeConversationModel homeConversationModel;
  TextEditingController _messageController = new TextEditingController();
  final FireStoreUtils _fireStoreUtils = FireStoreUtils();
  TextEditingController _groupNameController = TextEditingController();
  RecordingState currentRecordingState = RecordingState.HIDDEN;
  late Timer audioMessageTimer;
  String audioMessageTime = 'startRecording'.tr();
  FlutterSoundRecorder? _myRecorder = FlutterSoundRecorder();

  late String tempPathForAudioMessages;

  late Stream<ChatModel> chatStream;

  @override
  void initState() {
    super.initState();
    _myRecorder!.openAudioSession();
    homeConversationModel = widget.homeConversationModel;
    if (homeConversationModel.isGroupChat)
      _groupNameController.text =
          homeConversationModel.conversationModel?.name ?? '';
    setupStream();
  }

  setupStream() {
    chatStream = _fireStoreUtils
        .getChatMessages(homeConversationModel)
        .asBroadcastStream();
    chatStream.listen((chatModel) {
      if (mounted) {
        homeConversationModel.members = chatModel.members;
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          CALLS_ENABLED
              ? IconButton(
                  tooltip: 'voiceCall'.tr(),
                  iconSize: 20,
                  constraints: BoxConstraints(maxWidth: 24, maxHeight: 24),
                  icon: Icon(Icons.call),
                  onPressed: () {
                    homeConversationModel.isGroupChat
                        ? push(
                            context,
                            VoiceCallsGroupScreen(
                              isCaller: true,
                              homeConversationModel: homeConversationModel,
                              sessionDescription: null,
                              sessionType: null,
                              caller: MyAppState.currentUser!,
                            ),
                          )
                        : push(
                            context,
                            VoiceCallScreen(
                              isCaller: true,
                              homeConversationModel: homeConversationModel,
                              sessionDescription: null,
                              sessionType: null,
                            ),
                          );
                  },
                  color:
                      isDarkMode(context) ? Colors.grey.shade200 : Colors.white,
                )
              : Container(
                  width: 0,
                  height: 0,
                ),
          CALLS_ENABLED
              ? IconButton(
                  tooltip: 'videoCall'.tr(),
                  constraints: BoxConstraints(maxWidth: 24, maxHeight: 24),
                  iconSize: 20,
                  icon: Icon(Icons.videocam),
                  onPressed: () {
                    homeConversationModel.isGroupChat
                        ? push(
                            context,
                            VideoCallsGroupScreen(
                              isCaller: true,
                              homeConversationModel: homeConversationModel,
                              sessionDescription: null,
                              sessionType: null,
                              caller: MyAppState.currentUser!,
                            ),
                          )
                        : push(
                            context,
                            VideoCallScreen(
                              isCaller: true,
                              homeConversationModel: homeConversationModel,
                              sessionDescription: null,
                              sessionType: null,
                            ));
                  },
                  color:
                      isDarkMode(context) ? Colors.grey.shade200 : Colors.white,
                )
              : Container(
                  width: 0,
                  height: 0,
                ),
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                    child: ListTile(
                  dense: true,
                  onTap: () {
                    Navigator.pop(context);
                    homeConversationModel.isGroupChat
                        ? _onGroupChatSettingsClick()
                        : _onPrivateChatSettingsClick();
                  },
                  contentPadding: const EdgeInsets.all(0),
                  leading: Icon(
                    Icons.settings,
                    color: isDarkMode(context)
                        ? Colors.grey.shade200
                        : Colors.black,
                  ),
                  title: Text(
                    'settings'.tr(),
                    style: TextStyle(fontSize: 18),
                  ),
                ))
              ];
            },
          ),
        ],
        centerTitle: true,
        actionsIconTheme: IconThemeData(
            color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white),
        iconTheme: IconThemeData(
            color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white),
        backgroundColor: Color(COLOR_PRIMARY),
        title: homeConversationModel.isGroupChat
            ? Text(
                homeConversationModel.conversationModel?.name ?? '',
                style: TextStyle(
                    color: isDarkMode(context)
                        ? Colors.grey.shade200
                        : Colors.white,
                    fontWeight: FontWeight.bold),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    homeConversationModel.members.first.fullName(),
                    style: TextStyle(
                        color: isDarkMode(context)
                            ? Colors.grey.shade200
                            : Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: buildSubTitle(homeConversationModel.members.first),
                  )
                ],
              ),
      ),
      body: Builder(builder: (BuildContext innerContext) {
        return Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8, bottom: 8),
          child: Column(
            children: <Widget>[
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      currentRecordingState = RecordingState.HIDDEN;
                    });
                  },
                  child: StreamBuilder<ChatModel>(
                      stream: homeConversationModel.conversationModel != null
                          ? chatStream
                          : null,
                      initialData: ChatModel(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        } else {
                          if (snapshot.hasData &&
                              (snapshot.data?.message.isEmpty ?? true)) {
                            return Center(child: Text('noMessagesYet').tr());
                          } else {
                            return ListView.builder(
                                reverse: true,
                                itemCount: snapshot.data!.message.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return buildMessage(
                                      snapshot.data!.message[index],
                                      snapshot.data!.members);
                                });
                          }
                        }
                      }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: _onCameraClick,
                      icon: Icon(
                        Icons.camera_alt,
                        color: Color(COLOR_PRIMARY),
                      ),
                    ),
                    Expanded(
                        child: Padding(
                            padding: const EdgeInsets.only(left: 2.0, right: 2),
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: ShapeDecoration(
                                shape: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(360),
                                    ),
                                    borderSide:
                                        BorderSide(style: BorderStyle.none)),
                                color: isDarkMode(context)
                                    ? Colors.grey[700]
                                    : Colors.grey.shade200,
                              ),
                              child: Row(
                                children: <Widget>[
                                  InkWell(
                                    onTap: () => _onMicClicked(),
                                    child: Icon(
                                      Icons.mic,
                                      color: currentRecordingState ==
                                          RecordingState.HIDDEN
                                          ? Color(COLOR_PRIMARY)
                                          : Colors.red,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      onChanged: (s) {
                                        setState(() {});
                                      },
                                      onTap: () {
                                        setState(() {
                                          currentRecordingState =
                                              RecordingState.HIDDEN;
                                        });
                                      },
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      controller: _messageController,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 8),
                                        hintText: 'startTyping'.tr(),
                                        hintStyle:
                                            TextStyle(color: Colors.grey[400]),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(360),
                                            ),
                                            borderSide: BorderSide(
                                                style: BorderStyle.none)),
                                        enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(360),
                                            ),
                                            borderSide: BorderSide(
                                                style: BorderStyle.none)),
                                      ),
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      maxLines: 5,
                                      minLines: 1,
                                      keyboardType: TextInputType.multiline,
                                    ),
                                  ),
                                ],
                              ),
                            ))),
                    IconButton(
                        icon: Icon(
                          Icons.send,
                          color: _messageController.text.isEmpty
                              ? Color(COLOR_PRIMARY).withOpacity(.5)
                              : Color(COLOR_PRIMARY),
                        ),
                        onPressed: () async {
                          if (_messageController.text.isNotEmpty) {
                            _sendMessage(_messageController.text,
                                Url(mime: '', url: ''), '');
                            _messageController.clear();
                            setState(() {});
                          }
                        })
                  ],
                ),
              ),
              _buildAudioMessageRecorder(innerContext)
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAudioMessageRecorder(BuildContext innerContext) {
    return Visibility(
      visible: currentRecordingState != RecordingState.HIDDEN,
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(child: Center(child: Text(audioMessageTime))),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Stack(children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Visibility(
                          visible:
                              currentRecordingState == RecordingState.Recording,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: Color(COLOR_PRIMARY),
                              padding: EdgeInsets.only(top: 12, bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                side: BorderSide(style: BorderStyle.none),
                              ),
                            ),
                            child: Text(
                              'send',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ).tr(),
                            onPressed: () => _onSendRecord(),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Visibility(
                          visible:
                              currentRecordingState == RecordingState.Recording,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: Colors.grey.shade700,
                              padding: EdgeInsets.only(top: 12, bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                side: BorderSide(style: BorderStyle.none),
                              ),
                            ),
                            child: Text(
                              'cancel',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ).tr(),
                            onPressed: () => _onCancelRecording(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Visibility(
                      visible: currentRecordingState == RecordingState.VISIBLE,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.red,
                          padding: EdgeInsets.only(top: 12, bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            side: BorderSide(style: BorderStyle.none),
                          ),
                        ),
                        child: Text(
                          'record',
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ).tr(),
                        onPressed: () => _onStartRecording(innerContext),
                      ),
                    ),
                  ),
                ]),
              ),
            )
          ],
        ),
        height: MediaQuery.of(context).size.height * .3,
      ),
    );
  }

  Widget buildSubTitle(User friend) {
    String text = friend.active
        ? 'activeNow'.tr()
        : 'lastSeenOn'
            .tr(args: ['${setLastSeen(friend.lastOnlineTimestamp.seconds)}']);
    return Text(text,
        style: TextStyle(fontSize: 15, color: Colors.grey.shade200));
  }

  _onGroupChatSettingsClick() {
    final action = CupertinoActionSheet(
      message: Text(
        'groupChatSettings',
        style: TextStyle(fontSize: 15.0),
      ).tr(),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          child: Text('leaveGroup').tr(),
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            showProgress(context, 'leavingGroupChat'.tr(), false);
            bool isSuccessful = await _fireStoreUtils
                .leaveGroup(homeConversationModel.conversationModel!);
            hideProgress();
            if (isSuccessful) {
              Navigator.pop(context);
            }
          },
        ),
        CupertinoActionSheetAction(
          child: Text('renameGroup').tr(),
          isDefaultAction: true,
          onPressed: () async {
            Navigator.pop(context);
            showDialog(
                context: context,
                builder: (context) {
                  return _showRenameGroupDialog();
                });
          },
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text(
          'cancel',
        ).tr(),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  _onCameraClick() {
    final action = CupertinoActionSheet(
      message: Text(
        'sendMedia',
        style: TextStyle(fontSize: 15.0),
      ).tr(),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text('chooseImageFromGallery').tr(),
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            PickedFile? image =
                await _imagePicker.getImage(source: ImageSource.gallery);
            if (image != null) {
              Url url = await _fireStoreUtils.uploadChatImageToFireStorage(
                  File(image.path), context);
              _sendMessage('', url, '');
            }
          },
        ),
        CupertinoActionSheetAction(
          child: Text('chooseVideoFromGallery').tr(),
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            PickedFile? galleryVideo =
                await _imagePicker.getVideo(source: ImageSource.gallery);
            if (galleryVideo != null) {
              ChatVideoContainer videoContainer =
                  await _fireStoreUtils.uploadChatVideoToFireStorage(
                      File(galleryVideo.path), context);
              _sendMessage(
                  '', videoContainer.videoUrl, videoContainer.thumbnailUrl);
            }
          },
        ),
        CupertinoActionSheetAction(
          child: Text('takeAPicture').tr(),
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            PickedFile? image =
                await _imagePicker.getImage(source: ImageSource.camera);
            if (image != null) {
              Url url = await _fireStoreUtils.uploadChatImageToFireStorage(
                  File(image.path), context);
              _sendMessage('', url, '');
            }
          },
        ),
        CupertinoActionSheetAction(
          child: Text('recordVideo').tr(),
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            PickedFile? recordedVideo =
                await _imagePicker.getVideo(source: ImageSource.camera);
            if (recordedVideo != null) {
              ChatVideoContainer videoContainer =
                  await _fireStoreUtils.uploadChatVideoToFireStorage(
                      File(recordedVideo.path), context);
              _sendMessage(
                  '', videoContainer.videoUrl, videoContainer.thumbnailUrl);
            }
          },
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text(
          'cancel',
        ).tr(),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  Widget buildMessage(MessageData messageData, List<User> members) {
    if (messageData.senderID == MyAppState.currentUser!.userID) {
      return myMessageView(messageData);
    } else {
      return remoteMessageView(
          messageData,
          members.where((user) {
            return user.userID == messageData.senderID;
          }).first);
    }
  }

  Widget myMessageView(MessageData messageData) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Padding(
              padding: const EdgeInsetsDirectional.only(end: 12.0),
              child: _myMessageContentWidget(messageData)),
          displayCircleImage(messageData.senderProfilePictureURL, 35, false)
        ],
      ),
    );
  }

  Widget _myMessageContentWidget(MessageData messageData) {
    var mediaUrl = '';
    if (messageData.url.url.isNotEmpty) {
      if (messageData.url.mime.contains('image')) {
        mediaUrl = messageData.url.url;
      } else if (messageData.url.mime.contains('video')) {
        mediaUrl = messageData.videoThumbnail;
      } else if (messageData.url.mime.contains('audio')) {
        mediaUrl = messageData.url.url;
      }
    }
    if (mediaUrl.contains('audio')) {
      return Stack(
          clipBehavior: Clip.none,
          alignment: Directionality.of(context) == TextDirection.ltr
              ? Alignment.bottomRight
              : Alignment.bottomLeft,
          children: <Widget>[
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: -8,
              bottom: 0,
              child: Image.asset(
                Directionality.of(context) == TextDirection.ltr
                    ? 'assets/images/chat_arrow_right.png'
                    : 'assets/images/chat_arrow_left.png',
                color: Color(COLOR_ACCENT),
                height: 12,
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 50,
                maxWidth: 200,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(COLOR_ACCENT),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(
                    Radius.circular(8),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Stack(
                      clipBehavior: Clip.hardEdge,
                      alignment: Alignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 6, bottom: 6, right: 4, left: 4),
                          child: PlayerWidget(
                            url: messageData.url.url,
                            color: isDarkMode(context)
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                          // PlayerWidget(
                          //                           url: messageData.url.url,
                          //                           color: isDarkMode(context)
                          //                               ? Colors.grey.shade800
                          //                               : Colors.grey.shade200,
                          //                         )
                        ),
                      ]),
                ),
              ),
            ),
          ]);
    } else if (mediaUrl.isNotEmpty) {
      return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 50,
            maxWidth: 200,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(alignment: Alignment.center, children: [
              GestureDetector(
                onTap: () {
                  if (messageData.videoThumbnail.isEmpty) {
                    push(
                        context,
                        FullScreenImageViewer(
                          imageUrl: mediaUrl,
                        ));
                  }
                },
                child: Hero(
                  tag: mediaUrl,
                  child: CachedNetworkImage(
                    imageUrl: mediaUrl,
                    placeholder: (context, url) =>
                        Image.asset('assets/images/img_placeholder'
                            '.png'),
                    errorWidget: (context, url, error) =>
                        Image.asset('assets/images/error_image'
                            '.png'),
                  ),
                ),
              ),
              messageData.videoThumbnail.isNotEmpty
                  ? FloatingActionButton(
                      mini: true,
                      heroTag: messageData.messageID,
                      backgroundColor: Color(COLOR_ACCENT),
                      onPressed: () {
                        push(
                            context,
                            FullScreenVideoViewer(
                              heroTag: messageData.messageID,
                              videoUrl: messageData.url.url,
                            ));
                      },
                      child: Icon(
                        Icons.play_arrow,
                        color:
                            isDarkMode(context) ? Colors.black : Colors.white,
                      ),
                    )
                  : Container(
                      width: 0,
                      height: 0,
                    )
            ]),
          ));
    } else {
      return Stack(
          clipBehavior: Clip.none,
          alignment: Directionality.of(context) == TextDirection.ltr
              ? Alignment.bottomRight
              : Alignment.bottomLeft,
          children: <Widget>[
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: -8,
              bottom: 0,
              child: Image.asset(
                Directionality.of(context) == TextDirection.ltr
                    ? 'assets/images/chat_arrow_right.png'
                    : 'assets/images/chat_arrow_left.png',
                color: Color(COLOR_ACCENT),
                height: 12,
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 50,
                maxWidth: 200,
              ),
              child: Container(
                decoration: BoxDecoration(
                    color: Color(COLOR_ACCENT),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Stack(
                      clipBehavior: Clip.hardEdge,
                      alignment: Alignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 6, bottom: 6, right: 4, left: 4),
                          child: Text(
                            mediaUrl.isEmpty ? messageData.content : '',
                            textAlign: TextAlign.start,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                color: isDarkMode(context)
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 16),
                          ),
                        ),
                      ]),
                ),
              ),
            ),
          ]);
    }
  }

  Widget remoteMessageView(MessageData messageData, User sender) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Stack(
            alignment: Directionality.of(context) == TextDirection.ltr
                ? Alignment.bottomRight
                : Alignment.bottomLeft,
            children: <Widget>[
              displayCircleImage(sender.profilePictureURL, 35, false),
              Positioned.directional(
                  textDirection: Directionality.of(context),
                  end: 1,
                  bottom: 1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: homeConversationModel.members
                                .firstWhere((element) =>
                                    element.userID == messageData.senderID)
                                .active
                            ? Colors.green
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: isDarkMode(context)
                                ? Color(0xFF303030)
                                : Colors.white,
                            width: 1)),
                  ))
            ],
          ),
          Padding(
              padding: const EdgeInsetsDirectional.only(start: 12.0),
              child: _remoteMessageContentWidget(messageData)),
        ],
      ),
    );
  }

  Widget _remoteMessageContentWidget(MessageData messageData) {
    var mediaUrl = '';
    if (messageData.url.url.isNotEmpty) {
      if (messageData.url.mime.contains('image')) {
        mediaUrl = messageData.url.url;
      } else if (messageData.url.mime.contains('video')) {
        mediaUrl = messageData.videoThumbnail;
      } else if (messageData.url.mime.contains('audio')) {
        mediaUrl = messageData.url.url;
      }
    }
    if (mediaUrl.contains('audio')) {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Directionality.of(context) == TextDirection.ltr
            ? Alignment.bottomLeft
            : Alignment.bottomRight,
        children: <Widget>[
          Positioned.directional(
            textDirection: Directionality.of(context),
            start: -8,
            bottom: 0,
            child: Image.asset(
              Directionality.of(context) == TextDirection.ltr
                  ? 'assets/images/chat_arrow_left.png'
                  : 'assets/images/chat_arrow_right.png',
              color: isDarkMode(context) ? Colors.grey[600] : Colors.grey[300],
              height: 12,
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 50,
              maxWidth: 200,
            ),
            child: Container(
              decoration: BoxDecoration(
                  color: isDarkMode(context)
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Stack(
                    clipBehavior: Clip.hardEdge,
                    alignment: Alignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 6, bottom: 6, right: 4, left: 4),
                        child: PlayerWidget(
                          url: messageData.url.url,
                          color: isDarkMode(context)
                              ? Color(COLOR_ACCENT)
                              : Color(COLOR_PRIMARY),
                        ),
                        // PlayerWidget(
                        //   url: messageData.url.url,
                        //   color: isDarkMode(context)
                        //       ? Color(COLOR_ACCENT)
                        //       : Color(COLOR_PRIMARY),
                        // )
                      ),
                    ]),
              ),
            ),
          ),
        ],
      );
    } else if (mediaUrl.isNotEmpty) {
      return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 50,
            maxWidth: 200,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(alignment: Alignment.center, children: [
              GestureDetector(
                onTap: () {
                  if (messageData.videoThumbnail.isEmpty) {
                    push(
                        context,
                        FullScreenImageViewer(
                          imageUrl: mediaUrl,
                        ));
                  }
                },
                child: Hero(
                  tag: mediaUrl,
                  child: CachedNetworkImage(
                    imageUrl: mediaUrl,
                    placeholder: (context, url) =>
                        Image.asset('assets/images/img_placeholder'
                            '.png'),
                    errorWidget: (context, url, error) =>
                        Image.asset('assets/images/error_image'
                            '.png'),
                  ),
                ),
              ),
              messageData.videoThumbnail.isNotEmpty
                  ? FloatingActionButton(
                      mini: true,
                      heroTag: messageData.messageID,
                      backgroundColor: Color(COLOR_ACCENT),
                      onPressed: () {
                        push(
                            context,
                            FullScreenVideoViewer(
                              heroTag: messageData.messageID,
                              videoUrl: messageData.url.url,
                            ));
                      },
                      child: Icon(
                        Icons.play_arrow,
                        color:
                            isDarkMode(context) ? Colors.black : Colors.white,
                      ),
                    )
                  : Container(
                      width: 0,
                      height: 0,
                    )
            ]),
          ));
    } else {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Directionality.of(context) == TextDirection.ltr
            ? Alignment.bottomLeft
            : Alignment.bottomRight,
        children: <Widget>[
          Positioned.directional(
            textDirection: Directionality.of(context),
            start: -8,
            bottom: 0,
            child: Image.asset(
              Directionality.of(context) == TextDirection.ltr
                  ? 'assets/images/chat_arrow_left.png'
                  : 'assets/images/chat_arrow_right.png',
              color: isDarkMode(context) ? Colors.grey[600] : Colors.grey[300],
              height: 12,
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 50,
              maxWidth: 200,
            ),
            child: Container(
              decoration: BoxDecoration(
                  color:
                      isDarkMode(context) ? Colors.grey[600] : Colors.grey[300],
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Stack(
                    clipBehavior: Clip.hardEdge,
                    alignment: Alignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 6, bottom: 6, right: 4, left: 4),
                        child: Text(
                          mediaUrl.isEmpty ? messageData.content : '',
                          textAlign: TextAlign.start,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: isDarkMode(context)
                                ? Colors.white
                                : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ]),
              ),
            ),
          ),
        ],
      );
    }
  }

  Future<Track> loadTrack(String trackUrl) async => Track(trackPath: trackUrl);

  Future<bool> _checkChannelNullability(
      ConversationModel? conversationModel) async {
    if (conversationModel != null) {
      return true;
    } else {
      String channelID;
      User friend = homeConversationModel.members.first;
      User user = MyAppState.currentUser!;
      if (friend.userID.compareTo(user.userID) < 0) {
        channelID = friend.userID + user.userID;
      } else {
        channelID = user.userID + friend.userID;
      }

      ConversationModel conversation = ConversationModel(
          creatorId: user.userID,
          id: channelID,
          lastMessageDate: Timestamp.now(),
          lastMessage: 'sentAMessage'.tr(args: ['${user.fullName()}']));
      bool isSuccessful =
          await _fireStoreUtils.createConversation(conversation);
      if (isSuccessful) {
        homeConversationModel.conversationModel = conversation;
        setupStream();
        setState(() {});
      }
      return isSuccessful;
    }
  }

  _sendMessage(String content, Url url, String videoThumbnail) async {
    MessageData message;
    if (homeConversationModel.isGroupChat) {
      message = MessageData(
          content: content,
          created: Timestamp.now(),
          senderFirstName: MyAppState.currentUser!.firstName,
          senderID: MyAppState.currentUser!.userID,
          senderLastName: MyAppState.currentUser!.lastName,
          senderProfilePictureURL: MyAppState.currentUser!.profilePictureURL,
          url: url,
          videoThumbnail: videoThumbnail);
    } else {
      message = MessageData(
          content: content,
          created: Timestamp.now(),
          recipientFirstName: homeConversationModel.members.first.firstName,
          recipientID: homeConversationModel.members.first.userID,
          recipientLastName: homeConversationModel.members.first.lastName,
          recipientProfilePictureURL:
              homeConversationModel.members.first.profilePictureURL,
          senderFirstName: MyAppState.currentUser!.firstName,
          senderID: MyAppState.currentUser!.userID,
          senderLastName: MyAppState.currentUser!.lastName,
          senderProfilePictureURL: MyAppState.currentUser!.profilePictureURL,
          url: url,
          videoThumbnail: videoThumbnail);
    }
    if (url.mime.contains('image')) {
      message.content =
          'sentAnImage'.tr(args: ['${MyAppState.currentUser!.firstName}']);
    } else if (url.mime.contains('video')) {
      message.content =
          'sentAVideo'.tr(args: ['${MyAppState.currentUser!.firstName}']);
    } else if (url.mime.contains('audio')) {
      message.content = 'sentAVoiceMessage'
          .tr(args: ['${MyAppState.currentUser!.firstName}']);
    }
    if (await _checkChannelNullability(
        homeConversationModel.conversationModel)) {
      await _fireStoreUtils.sendMessage(
          homeConversationModel.members,
          homeConversationModel.isGroupChat,
          message,
          homeConversationModel.conversationModel!,
          true);
      homeConversationModel.conversationModel!.lastMessageDate =
          Timestamp.now();
      homeConversationModel.conversationModel!.lastMessage = message.content;

      await _fireStoreUtils
          .updateChannel(homeConversationModel.conversationModel!);
    } else {
      showAlertDialog(
          context, 'anErrorOccurred'.tr(), 'failedToSendMessage'.tr());
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _groupNameController.dispose();
    _myRecorder!.closeAudioSession();
    _myRecorder = null;
    super.dispose();
  }

  Widget _showRenameGroupDialog() {
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        elevation: 16,
        child: Container(
          height: 200,
          width: 350,
          child: Padding(
              padding: const EdgeInsets.only(
                  top: 40.0, left: 16, right: 16, bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  TextField(
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide(
                              color: Color(COLOR_ACCENT), width: 2.0)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0)),
                      labelText: 'groupName'.tr(),
                    ),
                  ),
                  Spacer(),
                  Wrap(
                    spacing: 30,
                    children: <Widget>[
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'cancel',
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ).tr()),
                      TextButton(
                          onPressed: () async {
                            if (_groupNameController.text.isNotEmpty) {
                              if (homeConversationModel
                                      .conversationModel!.name !=
                                  _groupNameController.text) {
                                showProgress(context,
                                    'renamingGroupPleaseWait'.tr(), false);
                                homeConversationModel.conversationModel!.name =
                                    _groupNameController.text.trim();
                                await _fireStoreUtils.updateChannel(
                                    homeConversationModel.conversationModel!);
                                hideProgress();
                              }
                              Navigator.pop(context);
                              setState(() {});
                            }
                          },
                          child: Text('rename',
                                  style: TextStyle(
                                      fontSize: 18, color: Color(COLOR_ACCENT)))
                              .tr()),
                    ],
                  )
                ],
              )),
        ));
  }

  _onPrivateChatSettingsClick() {
    final action = CupertinoActionSheet(
      message: Text(
        'chatSettings',
        style: TextStyle(fontSize: 15.0),
      ).tr(),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text('blockUser').tr(),
          onPressed: () async {
            Navigator.pop(context);
            showProgress(context, 'blockingUser'.tr(), false);
            bool isSuccessful = await _fireStoreUtils.blockUser(
                homeConversationModel.members.first, 'block');
            hideProgress();
            if (isSuccessful) {
              Navigator.pop(context);
              _showAlertDialog(
                  context,
                  'block'.tr(),
                  'hasBeenBlocked.'.tr(args: [
                    '${homeConversationModel.members.first.fullName()}'
                  ]));
            } else {
              _showAlertDialog(
                  context,
                  'block'.tr(),
                  'couldNotBlock'.tr(args: [
                    '${homeConversationModel.members.first.fullName()}'
                  ]));
            }
          },
        ),
        CupertinoActionSheetAction(
          child: Text('reportUser').tr(),
          onPressed: () async {
            Navigator.pop(context);
            showProgress(context, 'reportingUser'.tr(), false);
            bool isSuccessful = await _fireStoreUtils.blockUser(
                homeConversationModel.members.first, 'report');
            hideProgress();
            if (isSuccessful) {
              Navigator.pop(context);
              _showAlertDialog(
                  context,
                  'report'.tr(),
                  'hasBeenBlockedAndReported'.tr(args: [
                    '${homeConversationModel.members.first.fullName()}'
                  ]));
            } else {
              _showAlertDialog(
                  context,
                  'report'.tr(),
                  'couldNotReportAndBlock'.tr(args: [
                    '${homeConversationModel.members.first.fullName()}'
                  ]));
            }
          },
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text(
          'cancel',
        ).tr(),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  _showAlertDialog(BuildContext context, String title, String message) {
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(message),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  _onMicClicked() async {
    if (currentRecordingState == RecordingState.HIDDEN) {
      FocusScope.of(context).unfocus();
      Directory tempDir = await getTemporaryDirectory();
      var uniqueID = Uuid().v4();
      tempPathForAudioMessages = '${tempDir.path}/$uniqueID';
      currentRecordingState = RecordingState.VISIBLE;
    } else {
      currentRecordingState = RecordingState.HIDDEN;
    }
    setState(() {});
  }

  _onSendRecord() async {
    await _myRecorder!.stopRecorder();
    audioMessageTimer.cancel();
    setState(() {
      audioMessageTime = 'startRecording'.tr();
      currentRecordingState = RecordingState.HIDDEN;
    });
    Url url = await _fireStoreUtils.uploadAudioFile(
        File(tempPathForAudioMessages), context);
    _sendMessage('', url, '');
  }

  _onCancelRecording() async {
    await _myRecorder!.stopRecorder();
    audioMessageTimer.cancel();
    setState(() {
      audioMessageTime = 'Start Recording';
      currentRecordingState = RecordingState.VISIBLE;
    });
  }

  _onStartRecording(BuildContext innerContext) async {
    await _myRecorder!
        .startRecorder(toFile: tempPathForAudioMessages, codec: Codec.aacADTS);
    audioMessageTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        audioMessageTime = updateTime(audioMessageTimer);
      });
    });
    setState(() {
      currentRecordingState = RecordingState.Recording;
    });
  }
}
