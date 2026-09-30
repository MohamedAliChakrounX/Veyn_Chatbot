import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';

class HistoryStorage {
  static const String _key = 'veyn_mobile_conversations_v1';

  Future<List<Conversation>> loadConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];

      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveConversations(List<Conversation> conversations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(conversations.map((c) => c.toJson()).toList());
      await prefs.setString(_key, raw);
    } catch (e) {
      // Ignorer ou logguer
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      // Ignorer
    }
  }
}
