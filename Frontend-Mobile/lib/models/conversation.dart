import 'chat_message.dart';
import 'trip.dart';

class Conversation {
  final String id;
  final String title;
  final String? routeLabel;
  final String updatedAt;
  final List<ChatMessage> messages;
  final TripQuery trip;
  final int resultCount;
  final int bookingCount;

  const Conversation({
    required this.id,
    required this.title,
    this.routeLabel,
    required this.updatedAt,
    required this.messages,
    required this.trip,
    required this.resultCount,
    required this.bookingCount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (routeLabel != null) 'routeLabel': routeLabel,
        'updatedAt': updatedAt,
        'messages': messages.map((m) => m.toJson()).toList(),
        'trip': trip.toJson(),
        'resultCount': resultCount,
        'bookingCount': bookingCount,
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        routeLabel: json['routeLabel'] as String?,
        updatedAt: json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
        messages: (json['messages'] as List<dynamic>?)
                ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        trip: json['trip'] != null
            ? TripQuery.fromJson(json['trip'] as Map<String, dynamic>)
            : const TripQuery(),
        resultCount: (json['resultCount'] as num?)?.toInt() ?? 0,
        bookingCount: (json['bookingCount'] as num?)?.toInt() ?? 0,
      );
}
