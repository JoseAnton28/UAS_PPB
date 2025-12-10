import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';
import 'banlist_provider.dart';

class DeckProvider extends ChangeNotifier {
  List<Deck> _decks = [];
  Deck? _currentDeck;
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedBanlist = 'none';

  List<Deck> get decks => _decks;
  Deck? get currentDeck => _currentDeck;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedBanlist => _selectedBanlist;

  void setBanlistFormat(String format) {
    _selectedBanlist = format;
    notifyListeners();
  }

  Future<void> loadDecks() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _decks = await SupabaseService.instance.getAllDecks();
    } catch (e) {
      _errorMessage = 'Failed to load decks: $e';
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
    notifyListeners();
  }

  void setCurrentDeck(Deck deck) {
    _currentDeck = deck;
    notifyListeners();
  }

    void _addCard(YugiohCard card, List<DeckCard> section, BuildContext context) {
    if (_currentDeck == null) return;

        final banProvider = Provider.of<BanlistProvider>(context, listen: false);
    final status = _selectedBanlist != 'none'
        ? banProvider.getStatus(card)         : 'unlimited';

        if (status == 'forbidden') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${card.name} is Forbidden!'), backgroundColor: Colors.red),
      );
      return;
    }

        final currentCount = section
        .where((dc) => dc.card.id == card.id)
        .fold(0, (sum, dc) => sum + dc.quantity);

        if (status == 'limited' && currentCount >= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${card.name} is Limited (max 1)!'), backgroundColor: Colors.orange),
      );
      return;
    }

        if (status == 'semi_limited' && currentCount >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${card.name} is Semi-Limited (max 2)!'), backgroundColor: Colors.yellow[700]),
      );
      return;
    }

        final existingIndex = section.indexWhere((dc) => dc.card.id == card.id);
    if (existingIndex >= 0) {
      if (section[existingIndex].quantity < 3) {
        section[existingIndex].quantity++;
      }
    } else {
      section.add(DeckCard(card: card));
    }
    notifyListeners();
  }

    void addCardToMainDeck(YugiohCard card, BuildContext context) =>
      _addCard(card, _currentDeck!.mainDeck, context);

  void addCardToExtraDeck(YugiohCard card, BuildContext context) =>
      _addCard(card, _currentDeck!.extraDeck, context);

  void addCardToSideDeck(YugiohCard card, BuildContext context) =>
      _addCard(card, _currentDeck!.sideDeck, context);

  // Hapus kartu (tidak perlu validasi)
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

  // Save deck dengan validasi banlist
  Future<bool> saveDeck(BuildContext context) async {
    if (_currentDeck == null) {
      _errorMessage = 'No deck to save';
      notifyListeners();
      return false;
    }

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _errorMessage = 'You must be logged in to save decks.';
      notifyListeners();
      return false;
    }

    // Validasi banlist sebelum save
    if (_selectedBanlist != 'none') {
      final banProvider = context.read<BanlistProvider>();
      final result = banProvider.validateDeck(_currentDeck!);
      if (!result['valid']) {
        _errorMessage = 'Deck ilegal ($_selectedBanlist): ${result['issues'].join(', ')}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage), backgroundColor: Colors.red),
        );
        notifyListeners();
        return false;
      }
    }

    try {
      if (_currentDeck!.id == null) {
        final id = await SupabaseService.instance.createDeck(_currentDeck!);
        _currentDeck!.id = id;
      } else {
        await SupabaseService.instance.updateDeck(_currentDeck!);
      }
      await loadDecks();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save deck: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteDeck(dynamic id) async {
    try {
      await SupabaseService.instance.deleteDeck(id);
      await loadDecks();
      if (_currentDeck?.id == id) _currentDeck = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete deck: $e';
      notifyListeners();
    }
  }

  void clearCurrentDeck() {
    _currentDeck = null;
    notifyListeners();
  }
}