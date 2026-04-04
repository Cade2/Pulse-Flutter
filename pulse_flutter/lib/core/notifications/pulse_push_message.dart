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

  bool get hasDisplayContent {
    final String? trimmedTitle = title?.trim();
    final String? trimmedBody = body?.trim();
    return (trimmedTitle != null && trimmedTitle.isNotEmpty) ||
        (trimmedBody != null && trimmedBody.isNotEmpty);
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
