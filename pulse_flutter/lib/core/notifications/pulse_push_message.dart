class PulsePushMessage {
  const PulsePushMessage({
    this.messageId,
    this.title,
    this.body,
    this.sentTime,
    this.data = const <String, String>{},
  });

  final String? messageId;
  final String? title;
  final String? body;
  final DateTime? sentTime;
  final Map<String, String> data;

  factory PulsePushMessage.fromJson(Map<String, dynamic> json) {
    final Object? rawData = json['data'];
    final Map<String, String> parsedData = switch (rawData) {
      Map<Object?, Object?> values => values.map(
        (key, value) => MapEntry('$key', '$value'),
      ),
      _ => const <String, String>{},
    };

    final Object? rawSentTime = json['sentTime'];

    return PulsePushMessage(
      messageId: json['messageId'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      sentTime: rawSentTime is String && rawSentTime.isNotEmpty
          ? DateTime.tryParse(rawSentTime)
          : null,
      data: parsedData,
    );
  }

  bool get hasDisplayContent {
    final String? trimmedTitle = title?.trim();
    final String? trimmedBody = body?.trim();
    return (trimmedTitle != null && trimmedTitle.isNotEmpty) ||
        (trimmedBody != null && trimmedBody.isNotEmpty);
  }

  String get routingKey {
    return messageId ??
        Object.hash(title, body, sentTime, data).toUnsigned(32).toString();
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'messageId': messageId,
      'title': title,
      'body': body,
      'sentTime': sentTime?.toIso8601String(),
      'data': data,
    };
  }
}
