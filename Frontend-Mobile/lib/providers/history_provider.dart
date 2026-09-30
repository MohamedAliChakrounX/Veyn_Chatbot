import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../services/history_storage.dart';

class HistoryProvider extends ChangeNotifier {
  final HistoryStorage _storage = HistoryStorage();
  List<Conversation> _conversations = [];
  bool _isLoaded = false;

  List<Conversation> get conversations => _conversations;
  bool get isLoaded => _isLoaded;

  HistoryProvider() {
    load();
  }

  Future<void> load() async {
    _conversations = await _storage.loadConversations();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> addOrUpdate(Conversation conv) async {
    final index = _conversations.indexWhere((c) => c.id == conv.id);
    if (index >= 0) {
      _conversations[index] = conv;
    } else {
      _conversations.insert(0, conv);
    }
    notifyListeners();
    await _storage.saveConversations(_conversations);
  }

  Future<void> remove(String id) async {
    _conversations.removeWhere((c) => c.id == id);
    notifyListeners();
    await _storage.saveConversations(_conversations);
  }

  Future<void> clearAll() async {
    _conversations.clear();
    notifyListeners();
    await _storage.clearAll();
  }
}
