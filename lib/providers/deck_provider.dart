import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/supabase_service.dart';

class DeckProvider extends ChangeNotifier {
  List<Deck> _decks = [];
  Deck? _currentDeck;
  bool _isLoading = false;
  String _errorMessage = '';

  List<Deck> get decks => _decks;
  Deck? get currentDeck => _currentDeck;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadDecks() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _decks = await SupabaseService.instance.getAllDecks();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Failed to load decks: $e';
      print('❌ Load decks error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void createNewDeck(String name) {
    _currentDeck = Deck(
      name: name,
      mainDeck: [],
      extraDeck: [],
      sideDeck: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _errorMessage = '';
    notifyListeners();
  }

  void setCurrentDeck(Deck deck) {
    _currentDeck = deck;
    _errorMessage = '';
    notifyListeners();
  }

  void addCardToMainDeck(YugiohCard card) {
    if (_currentDeck == null) return;

    final existingIndex = _currentDeck!.mainDeck.indexWhere((dc) => dc.card.id == card.id);

    if (existingIndex >= 0) {
      if (_currentDeck!.mainDeck[existingIndex].quantity < 3) {
        _currentDeck!.mainDeck[existingIndex].quantity++;
      }
    } else {
      if (_currentDeck!.mainDeckCount < 60) {
        _currentDeck!.mainDeck.add(DeckCard(card: card, quantity: 1));
      }
    }

    notifyListeners();
  }

  void addCardToExtraDeck(YugiohCard card) {
    if (_currentDeck == null) return;

    final existingIndex = _currentDeck!.extraDeck.indexWhere((dc) => dc.card.id == card.id);

    if (existingIndex >= 0) {
      if (_currentDeck!.extraDeck[existingIndex].quantity < 3) {
        _currentDeck!.extraDeck[existingIndex].quantity++;
      }
    } else {
      if (_currentDeck!.extraDeckCount < 15) {
        _currentDeck!.extraDeck.add(DeckCard(card: card, quantity: 1));
      }
    }

    notifyListeners();
  }

  void addCardToSideDeck(YugiohCard card) {
    if (_currentDeck == null) return;

    final existingIndex = _currentDeck!.sideDeck.indexWhere((dc) => dc.card.id == card.id);

    if (existingIndex >= 0) {
      if (_currentDeck!.sideDeck[existingIndex].quantity < 3) {
        _currentDeck!.sideDeck[existingIndex].quantity++;
      }
    } else {
      if (_currentDeck!.sideDeckCount < 15) {
        _currentDeck!.sideDeck.add(DeckCard(card: card, quantity: 1));
      }
    }

    notifyListeners();
  }

  void removeCardFromMainDeck(YugiohCard card) {
    if (_currentDeck == null) return;

    final index = _currentDeck!.mainDeck.indexWhere((dc) => dc.card.id == card.id);
    if (index >= 0) {
      if (_currentDeck!.mainDeck[index].quantity > 1) {
        _currentDeck!.mainDeck[index].quantity--;
      } else {
        _currentDeck!.mainDeck.removeAt(index);
      }
    }

    notifyListeners();
  }

  void removeCardFromExtraDeck(YugiohCard card) {
    if (_currentDeck == null) return;

    final index = _currentDeck!.extraDeck.indexWhere((dc) => dc.card.id == card.id);
    if (index >= 0) {
      if (_currentDeck!.extraDeck[index].quantity > 1) {
        _currentDeck!.extraDeck[index].quantity--;
      } else {
        _currentDeck!.extraDeck.removeAt(index);
      }
    }

    notifyListeners();
  }

  void removeCardFromSideDeck(YugiohCard card) {
    if (_currentDeck == null) return;

    final index = _currentDeck!.sideDeck.indexWhere((dc) => dc.card.id == card.id);
    if (index >= 0) {
      if (_currentDeck!.sideDeck[index].quantity > 1) {
        _currentDeck!.sideDeck[index].quantity--;
      } else {
        _currentDeck!.sideDeck.removeAt(index);
      }
    }

    notifyListeners();
  }

  Future<bool> saveDeck() async {
    if (_currentDeck == null) {
      _errorMessage = 'No deck to save';
      notifyListeners();
      return false;
    }

    _errorMessage = '';

    try {
      print('🔄 Attempting to save deck: ${_currentDeck!.name}');
      print('📊 Main: ${_currentDeck!.mainDeckCount}, Extra: ${_currentDeck!.extraDeckCount}, Side: ${_currentDeck!.sideDeckCount}');

      if (_currentDeck!.id == null) {
        print('➕ Creating new deck...');
        final id = await SupabaseService.instance.createDeck(_currentDeck!);
        _currentDeck!.id = id;
        print('✅ Deck created with ID: $id');
      } else {
        print('🔄 Updating existing deck...');
        await SupabaseService.instance.updateDeck(_currentDeck!);
        print('✅ Deck updated successfully');
      }

      await loadDecks();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Save deck error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteDeck(dynamic id) async {
    try {
      await SupabaseService.instance.deleteDeck(id);
      await loadDecks();

      if (_currentDeck?.id == id) {
        _currentDeck = null;
      }

      _errorMessage = '';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete deck: $e';
      print('❌ Delete deck error: $e');
      notifyListeners();
    }
  }

  void clearCurrentDeck() {
    _currentDeck = null;
    _errorMessage = '';
    notifyListeners();
  }
}