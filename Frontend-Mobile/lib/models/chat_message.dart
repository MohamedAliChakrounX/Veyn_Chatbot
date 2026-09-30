import 'trip.dart';

enum MessageRole { user, assistant }

class QuickReply {
  final String label;
  final String value;

  const QuickReply({
    required this.label,
    required this.value,
  });

  Map<String, dynamic> toJson() => {'label': label, 'value': value};

  factory QuickReply.fromJson(Map<String, dynamic> json) => QuickReply(
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
      );
}

class TripConflict {
  final String field;
  final String question;
  final String currentLabel;
  final String proposedLabel;
  final Map<String, dynamic> proposed;

  const TripConflict({
    required this.field,
    required this.question,
    required this.currentLabel,
    required this.proposedLabel,
    required this.proposed,
  });

  Map<String, dynamic> toJson() => {
        'field': field,
        'question': question,
        'currentLabel': currentLabel,
        'proposedLabel': proposedLabel,
        'proposed': proposed,
      };

  factory TripConflict.fromJson(Map<String, dynamic> json) => TripConflict(
        field: json['field'] as String? ?? '',
        question: json['question'] as String? ?? '',
        currentLabel: json['currentLabel'] as String? ?? '',
        proposedLabel: json['proposedLabel'] as String? ?? '',
        proposed: (json['proposed'] as Map<String, dynamic>?) ?? {},
      );
}

class PassengerInfo {
  final String fullName;
  final String phone;
  final String? email;

  const PassengerInfo({
    required this.fullName,
    required this.phone,
    this.email,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phone,
        if (email != null && email!.isNotEmpty) 'email': email,
      };

  factory PassengerInfo.fromJson(Map<String, dynamic> json) => PassengerInfo(
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
      );
}

class BookingSummary {
  final String reference;
  final TripResult result;
  final int travelers;
  final Travelers? travelersDetail;
  final String? travelersLabel;
  final double total;
  final String currency;
  final TripStop boardingStop;
  final String routeLabel;
  final PassengerInfo? passenger;
  final String? paymentMethod;
  final String? cardType;
  final String? cardLast4;

  const BookingSummary({
    required this.reference,
    required this.result,
    required this.travelers,
    this.travelersDetail,
    this.travelersLabel,
    required this.total,
    required this.currency,
    required this.boardingStop,
    required this.routeLabel,
    this.passenger,
    this.paymentMethod,
    this.cardType,
    this.cardLast4,
  });

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'result': result.toJson(),
        'travelers': travelers,
        if (travelersDetail != null) 'travelersDetail': travelersDetail!.toJson(),
        if (travelersLabel != null) 'travelersLabel': travelersLabel,
        'total': total,
        'currency': currency,
        'boardingStop': boardingStop.toJson(),
        'routeLabel': routeLabel,
        if (passenger != null) 'passenger': passenger!.toJson(),
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (cardType != null) 'cardType': cardType,
        if (cardLast4 != null) 'cardLast4': cardLast4,
      };

  factory BookingSummary.fromJson(Map<String, dynamic> json) => BookingSummary(
        reference: json['reference'] as String? ?? '',
        result: TripResult.fromJson(json['result'] as Map<String, dynamic>),
        travelers: (json['travelers'] as num?)?.toInt() ?? 1,
        travelersDetail: json['travelersDetail'] != null
            ? Travelers.fromJson(json['travelersDetail'] as Map<String, dynamic>)
            : null,
        travelersLabel: json['travelersLabel'] as String?,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'DT',
        boardingStop: TripStop.fromJson(
            json['boardingStop'] as Map<String, dynamic>? ?? {}),
        routeLabel: json['routeLabel'] as String? ?? '',
        passenger: json['passenger'] != null
            ? PassengerInfo.fromJson(json['passenger'] as Map<String, dynamic>)
            : null,
        paymentMethod: json['paymentMethod'] as String?,
        cardType: json['cardType'] as String?,
        cardLast4: json['cardLast4'] as String?,
      );
}

class TripPrecisionItem {
  final String field;
  final String label;

  const TripPrecisionItem({
    required this.field,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'field': field,
        'label': label,
      };

  factory TripPrecisionItem.fromJson(Map<String, dynamic> json) =>
      TripPrecisionItem(
        field: json['field'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final List<String>? chipFields;
  final List<TripPrecisionItem>? precisions;
  final TripQuery? querySnapshot;
  final List<TripResult>? results;
  final TripConflict? conflict;
  final List<QuickReply>? quickReplies;
  final bool isError;
  final bool noResults;
  final BookingSummary? booking;
  final DateTime? timestamp;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.chipFields,
    this.precisions,
    this.querySnapshot,
    this.results,
    this.conflict,
    this.quickReplies,
    this.isError = false,
    this.noResults = false,
    this.booking,
    this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'text': text,
        if (chipFields != null) 'chipFields': chipFields,
        if (precisions != null)
          'precisions': precisions!.map((p) => p.toJson()).toList(),
        if (querySnapshot != null) 'querySnapshot': querySnapshot!.toJson(),
        if (results != null) 'results': results!.map((r) => r.toJson()).toList(),
        if (conflict != null) 'conflict': conflict!.toJson(),
        if (quickReplies != null)
          'quickReplies': quickReplies!.map((q) => q.toJson()).toList(),
        'isError': isError,
        'noResults': noResults,
        if (booking != null) 'booking': booking!.toJson(),
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String? ?? '',
        role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
        text: json['text'] as String? ?? '',
        chipFields: (json['chipFields'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        precisions: (json['precisions'] as List<dynamic>?)
            ?.map((e) => TripPrecisionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        querySnapshot: json['querySnapshot'] != null
            ? TripQuery.fromJson(json['querySnapshot'] as Map<String, dynamic>)
            : null,
        results: (json['results'] as List<dynamic>?)
            ?.map((e) => TripResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        conflict: json['conflict'] != null
            ? TripConflict.fromJson(json['conflict'] as Map<String, dynamic>)
            : null,
        quickReplies: (json['quickReplies'] as List<dynamic>?)
            ?.map((e) => QuickReply.fromJson(e as Map<String, dynamic>))
            .toList(),
        isError: json['isError'] as bool? ?? false,
        noResults: json['noResults'] as bool? ?? false,
        booking: json['booking'] != null
            ? BookingSummary.fromJson(json['booking'] as Map<String, dynamic>)
            : null,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String)
            : null,
      );
}

class AssistantResponse {
  final String reply;
  final Map<String, dynamic>? tripPatch;
  final List<String>? recognized;
  final List<TripResult>? results;
  final TripConflict? conflict;
  final List<String>? missing;
  final List<QuickReply>? quickReplies;
  final bool? noResults;

  const AssistantResponse({
    required this.reply,
    this.tripPatch,
    this.recognized,
    this.results,
    this.conflict,
    this.missing,
    this.quickReplies,
    this.noResults,
  });

  factory AssistantResponse.fromJson(Map<String, dynamic> json) =>
      AssistantResponse(
        reply: json['reply'] as String? ?? '',
        tripPatch: json['tripPatch'] as Map<String, dynamic>?,
        recognized: (json['recognized'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        results: (json['results'] as List<dynamic>?)
            ?.map((e) => TripResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        conflict: json['conflict'] != null
            ? TripConflict.fromJson(json['conflict'] as Map<String, dynamic>)
            : null,
        missing: (json['missing'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        quickReplies: (json['quickReplies'] as List<dynamic>?)
            ?.map((e) => QuickReply.fromJson(e as Map<String, dynamic>))
            .toList(),
        noResults: json['noResults'] as bool?,
      );
}
