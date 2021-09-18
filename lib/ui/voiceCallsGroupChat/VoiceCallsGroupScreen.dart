import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:instachatty/constants.dart';
import 'package:instachatty/model/HomeConversationModel.dart';
import 'package:instachatty/model/User.dart';
import 'package:instachatty/services/helper.dart';
import 'package:instachatty/ui/home/HomeScreen.dart';
import 'package:instachatty/ui/voiceCallsGroupChat/GroupVoiceCallsHandler.dart';
import 'package:wakelock/wakelock.dart';

class VoiceCallsGroupScreen extends StatefulWidget {
  final HomeConversationModel homeConversationModel;
  final bool isCaller;
  final String? sessionDescription;
  final String? sessionType;
  final User caller;

  const VoiceCallsGroupScreen(
      {Key? key,
      required this.homeConversationModel,
      required this.isCaller,
      required this.sessionDescription,
      required this.sessionType,
      required this.caller})
      : super(key: key);

  @override
  _VoiceCallsGroupScreenState createState() => _VoiceCallsGroupScreenState();
}

class _VoiceCallsGroupScreenState extends State<VoiceCallsGroupScreen> {
  GroupVoiceCallsHandler? _signaling;
  bool _isCallActive = false, _micOn = true, _speakerOn = true;
  late MediaStream _localStream;
  String _callDuration = '';

  initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays([]);
    if (!widget.isCaller) {
      FlutterRingtonePlayer.playRingtone();
      print('_VideoCallScreenState.initState');
    }
    _connect();
    if (!widget.isCaller) {
      _signaling?.startCountDown(context);
    }
    Wakelock.enable();
  }

  @override
  deactivate() {
    super.deactivate();
    _deactivate();
    _signaling?.countdownTimer?.cancel();
    if (_signaling?.timer != null && _signaling!.timer!.isActive)
      _signaling?.timer!.cancel();
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
    _signaling = new GroupVoiceCallsHandler(callerID: widget.caller.userID,
        isCaller: widget.isCaller,
        homeConversationModel: widget.homeConversationModel);

    _signaling?.onStateChange = (SignalingState state) {
      switch (state) {
        case SignalingState.CallStateNew:
          break;
        case SignalingState.CallStateBye:
          print(
              '_VideoCallsGroupScreenState._connect CallStateBye $_isCallActive');
          _isCallActive = false;
          this.setState(() {});
          Navigator.pop(context);
          break;
        case SignalingState.CallStateInvite:
        case SignalingState.CallStateConnected:
          {
            if (mounted) {
              if (_signaling?.timer == null) {
                print(
                    '_VoiceCallScreenState._connect _signaling.timer == null');
                // ignore: missing_return
                _signaling?.startCallDurationTimer((Timer timer) {
                  setState(() {
                    _callDuration = updateTime(timer);
                  });
                });
              } else {
                if (!(_signaling?.timer?.isActive ?? true)) {
                  print(
                      '_VoiceCallScreenState._connect !_signaling.timer.isActive');
                  // ignore: missing_return
                  _signaling?.startCallDurationTimer((Timer timer) {
                    setState(() {
                      _callDuration = updateTime(timer);
                    });
                  });
                }
              }
              print('_VoiceCallScreenState._connect');
              setState(() {
                _isCallActive = true;
              });
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
      }
    });
    _signaling?.onStreamListUpdate = ((streams) async {
      print(
          '_VideoCallsGroupScreenState._connect onStreamListUpdate $_isCallActive');
      if (mounted) {
        setState(() {
          if (!_isCallActive) _isCallActive = streams.isNotEmpty;
        });
      }
    });
    _signaling?.initCall(
        widget.homeConversationModel.members.first.userID, context);
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).unfocus();

    return Material(child: OrientationBuilder(builder: (context, orientation) {
      return Container(
        child: Stack(
            children: skipNulls([
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(widget
                        .homeConversationModel.members.first.profilePictureURL),
                    fit: BoxFit.cover,
                  ),
                ),
                child: new BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: orientation == Orientation.portrait ? 80 : 15),
                    child: SizedBox(width: double.infinity),
                  ),
                  displayCircleImage(
                      widget.homeConversationModel.members.first.profilePictureURL,
                      75,
                      true),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      _isCallActive
                      ? widget.homeConversationModel.conversationModel?.name ??
                          ''
                      : widget.isCaller
                          ? 'groupVoiceCalling'.tr(args: [
                              '${widget.homeConversationModel.conversationModel?.name}'
                            ])
                          : 'isGroupVoiceCallingYouAnd'.tr(namedArgs: {
                              'caller': '${widget.caller.fullName()}',
                              'groupName':
                                  '${widget.homeConversationModel.conversationModel?.name}'
                            }),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    _signaling?.timer != null && _signaling!.timer!.isActive
                    ? _callDuration
                    : widget.isCaller
                        ? 'ringing'.tr()
                        : '',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
                ],
              ),
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
                            _signaling?.countdownTimer?.cancel();
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
      _signaling!.countdownTimer?.cancel();
      _signaling!.bye();
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

  _deactivate() async {
    if (_signaling != null) await _signaling!.close();
  }
}
