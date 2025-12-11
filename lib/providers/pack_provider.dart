import 'dart:math';
import 'package:flutter/material.dart';
import '../models/pack_model.dart';
import '../models/card_model.dart';
import '../services/api_service.dart';

class PackProvider extends ChangeNotifier {
  final List<PackSet> _availablePacks = [
    PackSet(
      id: 'infinite-forbidden',
      name: 'Infinite Forbidden',
      code: 'INFO',
      releaseDate: DateTime(2025, 2, 15),
      imageUrl: 'https://images.ygoprodeck.com/images/sets/INFO.jpg',
      cardsPerPack: 5,
    ),
    PackSet(
      id: 'crossover-breakers',
      name: 'Crossover Breakers',
      code: 'CROB',
      releaseDate: DateTime(2024, 12, 7),
      imageUrl: 'https://static.wikia.nocookie.net/yugioh/images/1/1c/DBCB-BoosterAE.png/revision/latest?cb=20250308013256',
      cardsPerPack: 5,
    ),
    PackSet(
      id: 'rage-abyss',
      name: 'Rage of the Abyss',
      code: 'ROTA',
      releaseDate: DateTime(2024, 11, 23),
      imageUrl: 'https://images.ygoprodeck.com/images/sets/ROTA.jpg',
      cardsPerPack: 5,
    ),
    PackSet(
      id: 'terminal-world',
      name: 'Terminal World',
      code: 'TEWL',
      releaseDate: DateTime(2024, 8, 3),
      imageUrl: 'https://static.wikia.nocookie.net/yugioh/images/5/5e/TW01-BoosterJP.png/revision/latest?cb=20231012132418',
      cardsPerPack: 5,
    ),
    PackSet(
      id: 'phantom-nightmare',
      name: 'Phantom Nightmare',
      code: 'PHNI',
      releaseDate: DateTime(2024, 5, 25),
      imageUrl: 'https://images.ygoprodeck.com/images/sets/PHNI.jpg',
      cardsPerPack: 5,
    ),
  ];

  List<PackOpening> _openingHistory = [];
  Map<String, List<YugiohCard>> _packCards = {};
  List<YugiohCard> _allCards = [];
  bool _isLoading = false;

  List<PackSet> get availablePacks => _availablePacks;
  List<PackOpening> get openingHistory => _openingHistory;
  bool get isLoading => _isLoading;

  Future<void> loadCards() async {
    if (_allCards.isNotEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      _allCards = await ApiService.getAllCards();
      debugPrint('✅ Loaded ${_allCards.length} cards total');

      for (var pack in _availablePacks) {
        _packCards[pack.code] = _filterCardsForPack(pack.code);
        debugPrint('📦 ${pack.code}: ${_packCards[pack.code]?.length ?? 0} cards');
      }
    } catch (e) {
      debugPrint('❌ Error loading cards: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  List<YugiohCard> _filterCardsForPack(String packCode) {
    return _allCards.where((card) {
      if (card.cardSets == null) return false;
      return card.cardSets!.any((set) =>
          set.setCode.toUpperCase().startsWith(packCode.toUpperCase())
      );
    }).toList();
  }

  Future<PackOpening> openPack(PackSet pack) async {
    await loadCards();

    List<YugiohCard> availableCards = _packCards[pack.code] ?? [];

    if (availableCards.isEmpty) {
      debugPrint('⚠️ No specific cards for ${pack.code}, using random');
      availableCards = _allCards;
    }

    if (availableCards.isEmpty) {
      throw Exception('No cards available');
    }

    final random = Random();
    final openedCards = <OpenedCard>[];

    for (int i = 0; i < pack.cardsPerPack; i++) {
      final card = availableCards[random.nextInt(availableCards.length)];

      // Ambil rarity asli dari set
      String rarity = 'Common';
      String setCode = '';

      if (card.cardSets != null) {
        final matchingSet = card.cardSets!.firstWhere(
              (set) => set.setCode.toUpperCase().startsWith(pack.code.toUpperCase()),
          orElse: () => card.cardSets!.first,
        );
        rarity = matchingSet.setRarity;
        setCode = matchingSet.setCode;
      }

      openedCards.add(OpenedCard(
        cardId: card.id,
        name: card.name,
        imageUrl: card.imageUrl,
        rarity: rarity,
        setCode: setCode,
        isNew: random.nextDouble() < 0.3,
      ));
    }

    // Sortir berdasarkan rarity
    openedCards.sort((a, b) => _getRarityValue(b.rarity).compareTo(_getRarityValue(a.rarity)));

    final opening = PackOpening(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pack: pack,
      cards: openedCards,
      openedAt: DateTime.now(),
    );

    _openingHistory.insert(0, opening);
    notifyListeners();

    return opening;
  }

  int _getRarityValue(String rarity) {
    final rarityLower = rarity.toLowerCase();
    if (rarityLower.contains('secret')) return 5;
    if (rarityLower.contains('ultra')) return 4;
    if (rarityLower.contains('super')) return 3;
    if (rarityLower.contains('rare') && !rarityLower.contains('common')) return 2;
    return 1;
  }

  Color getRarityColor(String rarity) {
    final rarityLower = rarity.toLowerCase();
    if (rarityLower.contains('secret')) return Colors.purple;
    if (rarityLower.contains('ultra')) return Colors.yellow.shade700;
    if (rarityLower.contains('super')) return Colors.blue;
    if (rarityLower.contains('rare') && !rarityLower.contains('common')) {
      return Colors.grey.shade300;
    }
    return Colors.grey;
  }

  void clearHistory() {
    _openingHistory.clear();
    notifyListeners();
  }
}