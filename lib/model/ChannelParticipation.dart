class ChannelParticipation {
  String channel;

  String user;

  ChannelParticipation({this.channel = '', this.user = ''});

  factory ChannelParticipation.fromJson(Map<String, dynamic> parsedJson) {
    return new ChannelParticipation(
        channel: parsedJson['channel'] ?? '', user: parsedJson['user'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'channel': this.channel, 'user': this.user};
  }
}
