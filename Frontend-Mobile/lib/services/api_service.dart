import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/trip.dart';

class ApiService {
  static const String _prefKey = 'veyn_api_base_url';
  static String? _customBaseUrl;

  /// Liste des URLs candidates connues pour le développement local
  static const List<String> candidateUrls = [
    'http://127.0.0.1:8000',      // USB ADB reverse ou local
    'http://192.168.100.15:8000', // Wi-Fi machine de dev (IP actuelle active)
    'http://192.168.100.6:8000',  // Wi-Fi machine de dev (IP alternative)
    'http://10.0.2.2:8000',       // Émulateur Android
    'http://localhost:8000',      // Web / Desktop
  ];

  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Priorité 127.0.0.1:8000 (supporte adb reverse sur appareil réel et émulateur)
      return 'http://127.0.0.1:8000';
    }
    return 'http://localhost:8000';
  }

  static String get baseUrl => _customBaseUrl ?? defaultBaseUrl;

  static set baseUrl(String url) {
    _customBaseUrl = url.trim();
    saveBaseUrl(_customBaseUrl!);
  }

  /// Initialise la configuration de l'API au démarrage
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _customBaseUrl = saved.trim();
      }
    } catch (e) {
      debugPrint('[ApiService] Impossible de charger baseUrl depuis SharedPreferences: $e');
    }
  }

  /// Sauvegarde l'URL personnalisée dans SharedPreferences
  static Future<void> saveBaseUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, url.trim());
    } catch (e) {
      debugPrint('[ApiService] Erreur sauvegarde baseUrl: $e');
    }
  }

  /// Vérifie la disponibilité du backend sur l'URL donnée ou baseUrl
  Future<bool> checkHealth([String? urlToTest]) async {
    final target = (urlToTest ?? baseUrl).trim();
    try {
      final uri = Uri.parse('$target/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Tente de trouver automatiquement une URL qui répond parmi les candidates
  Future<String?> autoDetectWorkingUrl() async {
    // Tester d'abord l'URL actuelle
    if (await checkHealth(baseUrl)) return baseUrl;

    for (final url in candidateUrls) {
      if (url == baseUrl) continue;
      if (await checkHealth(url)) {
        baseUrl = url;
        debugPrint('[ApiService] URL active détectée avec succès: $url');
        return url;
      }
    }
    return null;
  }

  /// Envoie un message au backend FastAPI /api/chat
  Future<AssistantResponse?> sendChat({
    required String question,
    required TripQuery trip,
    required List<ChatMessage> messages,
    String language = 'fr',
    String sessionId = 'veyn-mobile-session',
  }) async {
    // Tentative avec l'URL configurée
    AssistantResponse? resp = await _sendChatInternal(
      targetUrl: baseUrl,
      question: question,
      trip: trip,
      messages: messages,
      language: language,
      sessionId: sessionId,
    );

    if (resp != null) return resp;

    // Fallback automatique si la première tentative échoue
    debugPrint('[ApiService] Échec sur $baseUrl, recherche d\'une URL alternative...');
    final workingUrl = await autoDetectWorkingUrl();
    if (workingUrl != null && workingUrl != baseUrl) {
      return await _sendChatInternal(
        targetUrl: workingUrl,
        question: question,
        trip: trip,
        messages: messages,
        language: language,
        sessionId: sessionId,
      );
    }

    return null;
  }

  Future<AssistantResponse?> _sendChatInternal({
    required String targetUrl,
    required String question,
    required TripQuery trip,
    required List<ChatMessage> messages,
    required String language,
    required String sessionId,
  }) async {
    try {
      final uri = Uri.parse('$targetUrl/api/chat');
      // On envoie les 6 DERNIERS messages (historique récent) pour conserver
      // le contexte de la conversation côté backend LLM.
      final recentMessages = messages.length > 6
          ? messages.sublist(messages.length - 6)
          : messages;

      final payload = {
        'session_id': sessionId,
        'question': question,
        'language': language,
        'trip': trip.toJson(),
        'messages': recentMessages
            .map((m) => {
                  'role': m.role == MessageRole.user ? 'user' : 'assistant',
                  'text': m.text,
                })
            .toList(),
      };

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        return AssistantResponse.fromJson(data);
      } else {
        debugPrint(
            '[ApiService] Erreur HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[ApiService] Exception lors de sendChat sur $targetUrl: $e');
      return null;
    }
  }

  /// Enregistre la réservation confirmée via POST /api/book
  Future<bool> bookTrip(BookingSummary summary) async {
    try {
      final uri = Uri.parse('$baseUrl/api/book');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(summary.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('[ApiService] Réservation enregistrée avec succès sur le backend.');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[ApiService] Erreur booking API: $e');
      return false;
    }
  }

  /// Récupère la liste des arrêts et stations depuis /api/locations
  Future<List<Map<String, dynamic>>> fetchLocations() async {
    try {
      final uri = Uri.parse('$baseUrl/api/locations');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        final stops = (data['stops'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
        return stops;
      }
    } catch (e) {
      debugPrint('[ApiService] Erreur fetchLocations: $e');
    }
    return [];
  }

  /// Transcrit un fichier audio enregistré via POST /api/transcribe (Whisper Groq)
  Future<String?> transcribeAudio(String filePath, {String language = 'fr'}) async {
    // 1. Tentative avec baseUrl actuelle
    String? text = await _transcribeInternal(
      targetUrl: baseUrl,
      filePath: filePath,
      language: language,
    );

    if (text != null) return text;

    // 2. Si échec (ex: connexion réseau changée), tenter détection automatique de l'URL
    debugPrint('[ApiService] Échec transcription sur $baseUrl, recherche d\'une URL alternative...');
    final workingUrl = await autoDetectWorkingUrl();
    if (workingUrl != null && workingUrl != baseUrl) {
      return await _transcribeInternal(
        targetUrl: workingUrl,
        filePath: filePath,
        language: language,
      );
    }

    return null;
  }

  Future<String?> _transcribeInternal({
    required String targetUrl,
    required String filePath,
    required String language,
  }) async {
    try {
      final uri = Uri.parse('$targetUrl/api/transcribe');
      final request = http.MultipartRequest('POST', uri);
      final filename = filePath.split(RegExp(r'[\\/]')).last;
      final effectiveName = filename.isNotEmpty ? filename : 'audio.wav';

      // Déterminer le sous-type MIME exact pour le fichier audio
      final ext = effectiveName.split('.').last.toLowerCase();
      final subType = switch (ext) {
        'wav'  => 'wav',
        'mp3'  => 'mpeg',
        'ogg'  => 'ogg',
        'webm' => 'webm',
        'mp4'  => 'mp4',
        _      => 'm4a',
      };

      debugPrint('[ApiService] Transcription audio: $effectiveName (audio/$subType) → $uri (lang=$language)');

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: effectiveName,
          contentType: MediaType('audio', subType),
        ),
      );

      request.fields['language'] = language;
      request.headers['Accept'] = 'application/json';

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[ApiService] Transcription HTTP ${response.statusCode}: ${response.body.length} chars');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        final text = (data['text'] as String?)?.trim() ?? '';
        debugPrint('[ApiService] Transcription reçue avec succès: "$text"');
        return text;
      } else {
        debugPrint(
            '[ApiService] Erreur transcription HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[ApiService] Exception lors de transcribeAudio sur $targetUrl: $e');
      return null;
    }
  }
}
