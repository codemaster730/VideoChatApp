import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:instachatty/constants.dart';
import 'package:instachatty/model/HomeConversationModel.dart';
import 'package:instachatty/services/helper.dart';
import 'package:instachatty/ui/videoCall/VideoCallsHandler.dart';
import 'package:wakelock/wakelock.dart';

class VideoCallScreen extends StatefulWidget {
  final HomeConversationModel homeConversationModel;
  final bool isCaller;
  final String? sessionDescription;
  final String? sessionType;

  const VideoCallScreen(
      {Key? key,
      required this.homeConversationModel,
      required this.isCaller,
      required this.sessionDescription,
      required this.sessionType})
      : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late VideoCallsHandler _signaling;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isCallActive = false, _micOn = true, _speakerOn = true;
  late MediaStream _localStream;

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
      _signaling.listenForMessages();

      _signaling.startCountDown(context);
      _signaling.setupOnRemoteHangupListener(context);
    }
    Wakelock.enable();
  }

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  deactivate() {
    super.deactivate();
    _signaling.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  @override
  void dispose() {
    _signaling.hangupSub?.cancel();
    _signaling.countdownTimer?.cancel();
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    if (!widget.isCaller) {
      print('FlutterRingtonePlayer dispose lets stop');
      FlutterRingtonePlayer.stop();
    }
    super.dispose();
    Wakelock.disable();
  }

  void _connect() async {
    _signaling = VideoCallsHandler(
        isCaller: widget.isCaller,
        homeConversationModel: widget.homeConversationModel);

    _signaling.onStateChange = (SignalingState state) {
      switch (state) {
        case SignalingState.CallStateNew:
          break;
        case SignalingState.CallStateBye:
          this.setState(() {
            _localRenderer.srcObject = null;
            _remoteRenderer.srcObject = null;
            _isCallActive = false;
          });
          break;
        case SignalingState.CallStateInvite:
        case SignalingState.CallStateConnected:
          {
            if (mounted)
              setState(() {
                _isCallActive = true;
              });
            break;
          }
        case SignalingState.CallStateRinging:
        case SignalingState.ConnectionClosed:
        case SignalingState.ConnectionError:
        case SignalingState.ConnectionOpen:
          break;
      }
    };
    _signaling.onLocalStream = ((stream) {
      if (mounted) {
        _localStream = stream;
        _localStream.getAudioTracks()[0].enableSpeakerphone(_speakerOn);
        _localStream.getAudioTracks()[0].setMicrophoneMute(!_micOn);
        setState(() {
          _localRenderer.srcObject = _localStream;
        });
      }
    });

    _signaling.onAddRemoteStream = ((stream) {
      if (mounted)
        setState(() {
          _isCallActive = true;
          _remoteRenderer.srcObject = stream;
        });
    });

    _signaling.onRemoveRemoteStream = ((stream) {
      if (mounted)
        setState(() {
          _isCallActive = false;
          _remoteRenderer.srcObject = null;
        });
    });
    if (widget.isCaller)
      _signaling.initCall(widget.homeConversationModel.members.first.fcmToken,
          widget.homeConversationModel.members.first.userID, context);
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).unfocus();

    return Material(child: OrientationBuilder(builder: (context, orientation) {
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
                      _remoteRenderer,
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
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
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
                    Text(
                      widget.isCaller
                          ? 'videoCallingName'.tr(args: [
                              '${widget.homeConversationModel.members.first.fullName()}'
                            ])
                          : 'isVideoCalling'.tr(args: [
                              '${widget.homeConversationModel.members.first.fullName()}'
                            ]),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  ],
                ),
          _isCallActive
              ? Positioned.directional(
                  textDirection: Directionality.of(context),
                  start: 20.0,
                  top: 20.0,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    color: Colors.black,
                    child: Container(
                        width:
                        orientation == Orientation.portrait ? 90.0 : 120.0,
                        height:
                        orientation == Orientation.portrait ? 120.0 : 90.0,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: RTCVideoView(_localRenderer, mirror: true,
                              objectFit: RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitCover,
                            ))),
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
                            _signaling.countdownTimer?.cancel();
                            _signaling.acceptCall(widget.sessionDescription!,
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
    _signaling.countdownTimer?.cancel();
    _signaling.bye();
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
}
