/// One inmate's answer to a poll.
class PollResponse {
  final String id;
  final String pollId;
  final String inmateId;
  /// e.g. "Yes" / "No"
  final String response;
  final DateTime? respondedAt;

  const PollResponse({
    required this.id,
    required this.pollId,
    required this.inmateId,
    required this.response,
    this.respondedAt,
  });

  factory PollResponse.fromJson(Map<String, dynamic> json) => PollResponse(
        id: json['id'] as String,
        pollId: json['poll_id'] as String,
        inmateId: json['inmate_id'] as String,
        response: json['response'] as String,
        respondedAt: json['responded_at'] != null
            ? DateTime.tryParse(json['responded_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'poll_id': pollId,
        'inmate_id': inmateId,
        'response': response,
        'responded_at': respondedAt?.toIso8601String(),
      };
}
