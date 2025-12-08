import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

class CardProvider extends ChangeNotifier {
  List<YugiohCard> _allCards = [];
  List<YugiohCard> _searchResults = [];
  List<YugiohCard> _favorites = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<YugiohCard> get allCards => _allCards;
  List<YugiohCard> get searchResults => _searchResults;
  List<YugiohCard> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadAllCards() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _allCards = await ApiService.getAllCards();
      _searchResults = _allCards;
    } catch (e) {
      _errorMessage = 'Failed to load cards: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchCards(String query) async {
    if (query.isEmpty) {
      _searchResults = _allCards;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await ApiService.searchCards(query);
    } catch (e) {
      _errorMessage = 'Search failed: $e';
      _searchResults = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void filterLocalCards(String query) {
    if (query.isEmpty) {
      _searchResults = _allCards;
    } else {
      _searchResults = _allCards
          .where((card) =>
      card.name.toLowerCase().contains(query.toLowerCase()) ||
          card.desc.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    try {
      _favorites = await SupabaseService.instance.getFavorites();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load favorites: $e';
    }
  }

  Future<void> toggleFavorite(YugiohCard card) async {
    try {
      final isFav = await SupabaseService.instance.isFavorite(card.id);

      if (isFav) {
        await SupabaseService.instance.removeFavorite(card.id);
      } else {
        await SupabaseService.instance.addFavorite(card);
      }

      await loadFavorites();
    } catch (e) {
      _errorMessage = 'Failed to toggle favorite: $e';
    }
  }

  Future<bool> isFavorite(int cardId) async {
    try {
      return await SupabaseService.instance.isFavorite(cardId);
    } catch (e) {
      return false;
    }
  }
}