import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/api_service.dart';
class CardProvider extends ChangeNotifier {
  List<YugiohCard> _allCards = [];
  List<YugiohCard> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<YugiohCard> get allCards => _allCards;
  List<YugiohCard> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadAllCards() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _allCards = await ApiService.getAllCards();
      _searchResults = _allCards;
      debugPrint('Loaded ${_allCards.length} cards');
    } catch (e) {
      _errorMessage = 'Failed to load cards. Check your connection.';
      debugPrint('Load cards error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchCards(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = _allCards;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await ApiService.searchCards(query);
    } catch (e) {
      _errorMessage = 'Search failed. Try again.';
      _searchResults = [];
      debugPrint('Search error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void filterLocalCards(String query) {
    if (query.trim().isEmpty) {
      _searchResults = _allCards;
    } else {
      final lowerQuery = query.toLowerCase();
      _searchResults = _allCards.where((card) {
        return card.name.toLowerCase().contains(lowerQuery) ||
            card.desc.toLowerCase().contains(lowerQuery);
      }).toList();
    }
    notifyListeners();
  }
}