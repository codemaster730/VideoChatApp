import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:instachatty/constants.dart';
import 'package:instachatty/model/HomeConversationModel.dart';
import 'package:instachatty/model/User.dart';
import 'package:instachatty/services/helper.dart';
import 'package:instachatty/ui/home/HomeScreen.dart';
import 'package:instachatty/ui/videoCallsGroupChat/GroupVideoCallsHandler.dart';
import 'package:wakelock/wakelock.dart';

class VideoCallsGroupScreen extends StatefulWidget {
  final HomeConversationModel homeConversationModel;
  final bool isCaller;
  final String? sessionDescription;
  final String? sessionType;
  final User caller;

  const VideoCallsGroupScreen(
      {Key? key,
      required this.homeConversationModel,
      required this.isCaller,
      required this.sessionDescription,
      required this.sessionType,
      required this.caller})
      : super(key: key);

  @override
  _VideoCallsGroupScreenState createState() => _VideoCallsGroupScreenState();
}

class _VideoCallsGroupScreenState extends State<VideoCallsGroupScreen> {
  late GroupVideoCallsHandler? _signaling;
  RTCVideoRenderer _bigRenderer = RTCVideoRenderer();
  List<RTCVideoRenderer> _listOfSmallRenderers = [];
  bool _isCallActive = false, _micOn = true, _speakerOn = true;
  late MediaStream _localStream;
  late MediaStream _bigStream;
  List<MediaStream> _listOfStreams = [];

  initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays([]);
    if (!widget.isCaller) {
      FlutterRingtonePlayer.playRingtone();
      print('_VideoCallScreenState.initState');
    }
    initRenderers();
    _connect();
    if (!widget.isCaller) {
      _signaling?.startCountDown(context);
    }
    Wakelock.enable();
  }

  initRenderers() async {
    await _bigRenderer.initialize();
  }

  @override
  deactivate() {
    super.deactivate();
    _deactivate();
    _signaling?.countdownTimer.cancel();
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    if (!widget.isCaller) {
      print('FlutterRingtonePlayer dispose lets stop');
      FlutterRingtonePlayer.stop();
    }
    HomeScreen.onGoingCall = false;
    Wakelock.disable();
    _signaling = null;
  }

  _connect() async {
    _signaling = new GroupVideoCallsHandler(
        callerID: widget.caller.userID,
        isCaller: widget.isCaller,
        homeConversationModel: widget.homeConversationModel);

    _signaling?.onStateChange = (SignalingState state) {
      switch (state) {
        case SignalingState.CallStateNew:
          break;
        case SignalingState.CallStateBye:
          _bigRenderer.srcObject = null;
          _listOfSmallRenderers.forEach((element) {
            element.srcObject = null;
          });
          print(
              '_VideoCallsGroupScreenState._connect CallStateBye $_isCallActive');
          _isCallActive = false;
          this.setState(() {});
          Navigator.pop(context);
          break;
        case SignalingState.CallStateInvite:
        case SignalingState.CallStateConnected:
          {
            print('_VideoCallsGroupScreenState._connect CallStateConnected '
                '$_isCallActive');
            if (mounted) {
              if (!_isCallActive) {
                setState(() {
                  _isCallActive = true;
                });
              }
            }
            break;
          }
        case SignalingState.CallStateRinging:
        case SignalingState.ConnectionClosed:
        case SignalingState.ConnectionError:
        case SignalingState.ConnectionOpen:
          break;
      }
    };
    _signaling?.onLocalStream = ((stream) {
      if (mounted) {
        _localStream = stream;
        _localStream.getAudioTracks()[0].enableSpeakerphone(_speakerOn);
        _localStream.getAudioTracks()[0].setMicrophoneMute(!_micOn);
        setState(() {
          _bigStream = _localStream;
          _bigRenderer.srcObject = _bigStream;
        });
      }
    });

    _signaling?.onStreamListUpdate = ((streams) async {
      print(
          '_VideoCallsGroupScreenState._connect onStreamListUpdate $_isCallActive');
      if (mounted) {
        _listOfStreams.clear();
        _listOfStreams.addAll(streams);
        _listOfSmallRenderers.forEach((element) {
          element.dispose();
        });
        _listOfSmallRenderers.clear();
        await Future.forEach(_listOfStreams, (MediaStream element) async {
          RTCVideoRenderer videoRenderer = RTCVideoRenderer();
          await videoRenderer.initialize();
          videoRenderer.srcObject = element;
          _listOfSmallRenderers.add(videoRenderer);
        });
        _bigStream = _localStream;
        _bigRenderer.srcObject = _bigStream;
        setState(() {
          if (!_isCallActive)
            _isCallActive = streams.isEmpty ? false : true;
        });
      }
    });
    _signaling?.initCall(
        widget.homeConversationModel.members.first.userID, context);
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).unfocus();

    return Scaffold(body: OrientationBuilder(builder: (context, orientation) {
      return Container(
        child: Stack(
            children: skipNulls([
              _isCallActive
                  ? Positioned(
                top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: RTCVideoView(
                      _bigRenderer,
                      mirror: true,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                    decoration: BoxDecoration(color: Color(COLOR_PRIMARY)),
                  ),
                )
                  : null,
              _isCallActive
                  ? null
                  : Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                height: MediaQuery
                    .of(context)
                    .size
                    .height,
                decoration: new BoxDecoration(
                  image: new DecorationImage(
                    image: NetworkImage(widget.homeConversationModel.members
                        .first.profilePictureURL),
                    fit: BoxFit.cover,
                  ),
                ),
                child: new BackdropFilter(
                  filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: new Container(
                    decoration: new BoxDecoration(
                        color: Colors.black.withOpacity(0.3)),
                    ),
                  ),
                ),
          _isCallActive
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(
                          vertical:
                              orientation == Orientation.portrait ? 80 : 15),
                      child: SizedBox(width: double.infinity),
                    ),
                    displayCircleImage(
                        widget.homeConversationModel.members.first
                            .profilePictureURL,
                        75,
                        true),
                    SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        widget.isCaller
                            ? 'groupVideoCalling'.tr(args: [
                          '${widget.homeConversationModel.conversationModel?.name}'
                              ])
                            : 'someoneGroupVideoCall'.tr(namedArgs: {
                                'caller': '${widget.caller.fullName()}',
                                'groupName':
                                '${widget.homeConversationModel.conversationModel?.name}'
                              }),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    )
                  ],
                ),
          _isCallActive
              ? Positioned(
            left: 20.0,
            top: 20.0,
            right: 20,
            child: SizedBox(
              height: orientation == Orientation.portrait
                  ? 120.0
                  : 90.0,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: _listOfStreams.length,
                itemBuilder: (BuildContext context, int index) =>
                    _buildSmallVideoRenderer(context, index, orientation),
              ),
            ),
          )
              : null,
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: skipNulls(
                [
                  widget.isCaller || _isCallActive
                      ? null
                      : FloatingActionButton(
                      backgroundColor: Colors.green,
                          heroTag: 'answerFAB',
                          child: Icon(Icons.call),
                          onPressed: () {
                            FlutterRingtonePlayer.stop();
                            print(
                                '_VideoCallsGroupScreenState.build countdownTimer.cancel()');
                            _signaling?.countdownTimer.cancel();
                            _signaling?.acceptCall(widget.sessionDescription!,
                                widget.sessionType!);
                            setState(() {
                              _isCallActive = true;
                            });
                          }),
                  _isCallActive
                      ? FloatingActionButton(
                          backgroundColor: Color(COLOR_ACCENT),
                          heroTag: 'speakerFAB',
                          child: Icon(
                              _speakerOn ? Icons.volume_up : Icons.volume_off),
                          onPressed: _speakerToggle,
                        )
                      : null,
                  FloatingActionButton(
                    heroTag: 'hangupFAB',
                    onPressed: () => _hangUp(),
                    tooltip: 'hangup'.tr(),
                    child: Icon(Icons.call_end),
                    backgroundColor: Colors.pink,
                  ),
                  _isCallActive
                      ? FloatingActionButton(
                          backgroundColor: Color(COLOR_ACCENT),
                          heroTag: 'micFAB',
                          child: Icon(_micOn ? Icons.mic : Icons.mic_off),
                          onPressed: _micToggle,
                        )
                      : null
                ],
              ),
            ),
          ),
        ])),
      );
    }));
  }

  _hangUp() {
    if (_signaling != null) {
      _signaling?.countdownTimer.cancel();
      _signaling?.bye();
    }
    if (!widget.isCaller) {
      print('FlutterRingtonePlayer _hangUp lets stop');
      FlutterRingtonePlayer.stop();
    }
    Navigator.pop(context);
  }

  _micToggle() {
    setState(() {
      _micOn = _micOn ? false : true;
      _localStream.getAudioTracks()[0].setMicrophoneMute(!_micOn);
    });
  }

  _speakerToggle() {
    setState(() {
      _speakerOn = _speakerOn ? false : true;
      _localStream.getAudioTracks()[0].enableSpeakerphone(_speakerOn);
    });
  }

  void _deactivate() async {
    if (_signaling != null) await _signaling?.close();

    _bigRenderer.dispose();
    if (_listOfSmallRenderers.isNotEmpty)
      Future.forEach(_listOfSmallRenderers, (RTCVideoRenderer element) {
        element.dispose();
      });
  }

  Widget _buildSmallVideoRenderer(BuildContext context,
      int index, Orientation orientation) {
    return InkWell(
      onTap: () {
        MediaStream smallStream = _listOfStreams[index];
        _listOfStreams[index] = _bigStream;
        _listOfSmallRenderers[index].srcObject = _bigStream;
        _bigStream = smallStream;
        _bigRenderer.srcObject = _bigStream;
        setState(() {});
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        color: Colors.black,
        child: Container(
            width: orientation == Orientation.portrait
                ? 90.0
                : 120.0,
            height: orientation == Orientation.portrait
                ? 120.0
                : 90.0,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: RTCVideoView(
                  _listOfSmallRenderers[index], mirror: true,
                  objectFit: RTCVideoViewObjectFit
                      .RTCVideoViewObjectFitCover,))),
      ),
    );
  }
}
