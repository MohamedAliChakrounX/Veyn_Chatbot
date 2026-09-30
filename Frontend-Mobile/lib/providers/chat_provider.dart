import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../services/api_service.dart';
import '../services/nlu_fallback.dart';
import 'history_provider.dart';
import 'trip_provider.dart';

enum ChatStatus { idle, thinking, searching, error }

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  late String _conversationId;
  List<ChatMessage> _messages = [];
  ChatStatus _status = ChatStatus.idle;
  String? _lastUserText;

  String get conversationId => _conversationId;
  List<ChatMessage> get messages => _messages;
  ChatStatus get status => _status;

  ChatProvider() {
    _startFresh();
  }

  void _startFresh([String lang = 'fr']) {
    _conversationId = 'conv-${DateTime.now().millisecondsSinceEpoch}';
    String welcomeText =
        'Bonjour ! Où souhaitez-vous voyager aujourd’hui ?';
    if (lang == 'ar') {
      welcomeText =
          'مرحباً بك ! إلى أين ترغب في السفر اليوم؟';
    } else if (lang == 'en') {
      welcomeText =
          'Hello! Where would you like to travel today?';
    }
    _messages = [
      ChatMessage(
        id: 'msg-welcome',
        role: MessageRole.assistant,
        text: welcomeText,
        timestamp: DateTime.now(),
      ),
    ];
    _status = ChatStatus.idle;
    _lastUserText = null;
    notifyListeners();
  }

  void updateLanguage(String lang) {
    if (_messages.length == 1 && _messages.first.id == 'msg-welcome') {
      _startFresh(lang);
    }
  }

  void startNewConversation(TripProvider tripProvider, [String lang = 'fr']) {
    tripProvider.resetTrip();
    _startFresh(lang);
  }

  void openConversation(Conversation conv, TripProvider tripProvider) {
    _conversationId = conv.id;
    _messages = List.from(conv.messages);
    _status = ChatStatus.idle;
    tripProvider.setTrip(conv.trip);
    notifyListeners();
  }

  Future<void> sendMessage(
    String text,
    TripProvider tripProvider,
    HistoryProvider historyProvider, {
    String language = 'fr',
  }) async {
    final clean = text.trim();
    if (clean.isEmpty && tripProvider.trip.isEmpty) return;

    final defaultText = language == 'ar'
        ? 'البحث بهذه المعلومات'
        : language == 'en'
            ? 'Search with this information'
            : 'Recherche avec les critères précisés ci-dessus';

    // Instantané figé et immuable des précisions au moment de l'envoi de la question
    final activeTripSnapshot = tripProvider.trip;
    final currentChips = tripProvider.chipsFor(language);
    final frozenPrecisions = currentChips
        .map((c) => TripPrecisionItem(field: c.field, label: c.label))
        .toList();

    final queryText = clean.isNotEmpty ? clean : defaultText;

    final userMessage = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      text: queryText,
      chipFields: frozenPrecisions.map((c) => c.field).toList(),
      precisions: frozenPrecisions,
      querySnapshot: activeTripSnapshot,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _lastUserText = clean;
    _status = ChatStatus.searching;
    notifyListeners();

    try {
      // 1. Appel au backend FastAPI réel basé exactement sur le snapshot de la question
      debugPrint('[ChatProvider] sendChat → URL: ${ApiService.baseUrl}, question: "$queryText"');
      final response = await _apiService.sendChat(
        question: queryText,
        trip: activeTripSnapshot,
        messages: _messages,
        language: language,
      );
      debugPrint('[ChatProvider] Réponse reçue: ${response == null ? 'NULL (fallback)' : 'OK (reply=${response.reply.length} chars, results=${response.results?.length ?? 0})'}');

      if (response != null) {
        if (response.tripPatch != null && response.tripPatch!.isNotEmpty) {
          tripProvider.patchTrip(response.tripPatch!);
        }

        // Calcule les précisions effectivement détectées pour ce message :
        // 1. Celles du dashboard (snapshot figé de l'utilisateur au moment de l'envoi)
        // 2. Si vides, celles reconnues par le NLU backend après application du tripPatch
        List<TripPrecisionItem> detectedPrecisions = frozenPrecisions;
        if (detectedPrecisions.isEmpty) {
          final updatedChips = tripProvider.chipsFor(language);
          if (response.recognized != null && response.recognized!.isNotEmpty) {
            // Filtrer uniquement les champs que le backend a reconnus
            detectedPrecisions = updatedChips
                .where((c) => response.recognized!.contains(c.field))
                .map((c) => TripPrecisionItem(field: c.field, label: c.label))
                .toList();
          }
          // Fallback : tout le trip si on a des résultats mais pas de champs filtrés
          if (detectedPrecisions.isEmpty && updatedChips.isNotEmpty &&
              response.results != null && response.results!.isNotEmpty) {
            detectedPrecisions = updatedChips
                .map((c) => TripPrecisionItem(field: c.field, label: c.label))
                .toList();
          }
        }

        final assistantMessage = ChatMessage(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch + 1}',
          role: MessageRole.assistant,
          text: response.reply,
          chipFields: response.recognized,
          precisions: detectedPrecisions.isNotEmpty ? detectedPrecisions : null,
          results: response.results,
          conflict: response.conflict,
          quickReplies: response.quickReplies,
          noResults: response.noResults ?? false,
          timestamp: DateTime.now(),
        );

        _messages.add(assistantMessage);
        _status = ChatStatus.idle;

      } else {
        // 2. Repli de secours local si le serveur est inaccessible
        final fallback = NluFallback.processMessage(clean, activeTripSnapshot);
        if (fallback.tripPatch != null && fallback.tripPatch!.isNotEmpty) {
          tripProvider.patchTrip(fallback.tripPatch!);
        }

        final assistantMessage = ChatMessage(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch + 1}',
          role: MessageRole.assistant,
          text: fallback.reply,
          chipFields: fallback.recognized,
          results: fallback.results,
          conflict: fallback.conflict,
          quickReplies: fallback.quickReplies,
          noResults: fallback.noResults ?? false,
          timestamp: DateTime.now(),
        );

        _messages.add(assistantMessage);
        _status = ChatStatus.idle;
      }
    } catch (e) {
      final errText = language == 'ar'
          ? 'عذراً، حدث خطأ أثناء معالجة طلبك. يرجى المحاولة مرة أخرى.'
          : language == 'en'
              ? 'Sorry, an error occurred while processing your request. Please try again.'
              : 'Désolé, une erreur est survenue lors du traitement de votre demande. Veuillez réessayer.';
      _messages.add(ChatMessage(
        id: 'msg-err-${DateTime.now().millisecondsSinceEpoch}',
        role: MessageRole.assistant,
        text: errText,
        isError: true,
        timestamp: DateTime.now(),
      ));
      _status = ChatStatus.error;
    }

    notifyListeners();
    _saveToHistory(tripProvider, historyProvider);
  }

  Future<void> confirmBooking(
    BookingSummary booking,
    TripProvider tripProvider,
    HistoryProvider historyProvider, {
    String language = 'fr',
  }) async {
    // 1. Appel à POST /api/book
    await _apiService.bookTrip(booking);

    // 2. Message de confirmation localisé
    final bookingText = language == 'ar'
        ? 'تم الحجز بنجاح — المرجع ${booking.reference} · ${booking.routeLabel}.'
        : language == 'en'
            ? 'Booking confirmed — reference ${booking.reference} · ${booking.routeLabel}.'
            : 'Réservation effectuée avec succès — référence ${booking.reference} · ${booking.routeLabel}.';

    final bookingMsg = ChatMessage(
      id: 'booking-${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      text: bookingText,
      booking: booking,
      timestamp: DateTime.now(),
    );

    _messages.add(bookingMsg);
    tripProvider.resetTrip();
    notifyListeners();
    _saveToHistory(tripProvider, historyProvider);
  }

  void resolveConflict(
    String messageId,
    TripConflict conflict,
    bool useProposed,
    TripProvider tripProvider,
    HistoryProvider historyProvider,
  ) {
    if (useProposed) {
      tripProvider.patchTrip(conflict.proposed);
    }
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index >= 0) {
      // Retirer le conflit une fois résolu
      final old = _messages[index];
      _messages[index] = ChatMessage(
        id: old.id,
        role: old.role,
        text: old.text,
        chipFields: old.chipFields,
        precisions: old.precisions,
        querySnapshot: old.querySnapshot,
        results: old.results,
        conflict: null,
        quickReplies: old.quickReplies,
        isError: old.isError,
        noResults: old.noResults,
        booking: old.booking,
        timestamp: old.timestamp,
      );
      notifyListeners();
    }
    _saveToHistory(tripProvider, historyProvider);
  }

  void retry(TripProvider tripProvider, HistoryProvider historyProvider) {
    if (_lastUserText != null) {
      sendMessage(_lastUserText!, tripProvider, historyProvider);
    }
  }

  void _saveToHistory(
    TripProvider tripProvider,
    HistoryProvider historyProvider,
  ) {
    final firstUserMsg = _messages
        .firstWhere(
          (m) => m.role == MessageRole.user,
          orElse: () => const ChatMessage(
            id: '',
            role: MessageRole.user,
            text: 'Nouvelle recherche',
          ),
        )
        .text;

    final conv = Conversation(
      id: _conversationId,
      title: firstUserMsg,
      routeLabel: tripProvider.routeLabel,
      updatedAt: DateTime.now().toIso8601String(),
      messages: List.from(_messages),
      trip: tripProvider.trip,
      resultCount: _messages.fold(0, (acc, m) => acc + (m.results?.length ?? 0)),
      bookingCount: _messages.where((m) => m.booking != null).length,
    );

    historyProvider.addOrUpdate(conv);
  }
}
