/// A mess food poll: "Dinner tomorrow?" with options + scheduling.
class Poll {
  final String id;
  final String propertyId;
  /// breakfast | lunch | dinner
  final String mealType;
  /// ISO date the meal is FOR (typically tomorrow).
  final String forDate;
  /// ISO datetime to send the poll.
  final String? sendAt;
  /// ISO datetime to auto-close the poll.
  final String? closeAt;
  final bool recurring;
  final List<String> options;

  const Poll({
    required this.id,
    required this.propertyId,
    required this.mealType,
    required this.forDate,
    this.sendAt,
    this.closeAt,
    this.recurring = false,
    this.options = const ['Yes', 'No'],
  });

  factory Poll.fromJson(Map<String, dynamic> json) => Poll(
        id: json['id'] as String,
        propertyId: json['property_id'] as String,
        mealType: json['meal_type'] as String,
        forDate: json['for_date'] as String,
        sendAt: json['send_at'] as String?,
        closeAt: json['close_at'] as String?,
        recurring: json['recurring'] as bool? ?? false,
        options: List<String>.from(json['options'] as List? ?? const []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'meal_type': mealType,
        'for_date': forDate,
        'send_at': sendAt,
        'close_at': closeAt,
        'recurring': recurring,
        'options': options,
      };
}
