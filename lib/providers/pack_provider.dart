import 'dart:math';
import 'package:flutter/material.dart';
import '../models/pack_model.dart';
import '../models/card_model.dart';
import '../services/api_service.dart';

class PackProvider extends ChangeNotifier {
  final List<PackSet> _availablePacks = [
    PackSet(
      id: 'burst-protocol',
      name: 'Burst of Destiny Protocol',
      code: 'BODE',
      releaseDate: DateTime(2021, 11, 6),
      imageUrl: 'https://images.ygoprodeck.com/images/sets/BODE.jpg',
      cardsPerPack: 5,
      rarities: ['Common', 'Rare', 'Super Rare', 'Ultra Rare', 'Secret Rare'],
    ),
    PackSet(
      id: 'phantom-revenge',
      name: 'Phantom Nightmare',
      code: 'PHNI',
      releaseDate: DateTime(2024, 5, 25),
      imageUrl: 'https://images.ygoprodeck.com/images/sets/PHNI.jpg',
      cardsPerPack: 5,
      rarities: ['Common', 'Rare', 'Super Rare', 'Ultra Rare', 'Secret Rare'],
    ),
    PackSet(
      id: 'doom-dimension',
      name: 'Dimension Force',
      code: 'DIFO',
      releaseDate: DateTime(2022, 5, 7),
      imageUrl: 'https://images.ygoprodeck.com/images/sets/DIFO.jpg',
      cardsPerPack: 5,
      rarities: ['Common', 'Rare', 'Super Rare', 'Ultra Rare', 'Secret Rare'],
    ),
    PackSet(
      id: 'justice-hunter',
      name: 'Darkwing Blast',
      code: 'DABL',
      releaseDate: DateTime(2022, 11, 5),
      imageUrl: 'https://images.ygoprodeck.com/images/sets/DABL.jpg',
      cardsPerPack: 5,
      rarities: ['Common', 'Rare', 'Super Rare', 'Ultra Rare', 'Secret Rare'],
    ),
    PackSet(
      id: 'duelist-advance',
      name: 'Photon Hypernova',
      code: 'PHHY',
      releaseDate: DateTime(2023, 2, 11),
      imageUrl: 'https://images.ygoprodeck.com/images/sets/PHHY.jpg',
      cardsPerPack: 5,
      rarities: ['Common', 'Rare', 'Super Rare', 'Ultra Rare', 'Secret Rare'],
    ),
    PackSet(
      id: 'alliance-insight',
      name: 'Cyberstorm Access',
      code: 'CYAC',
      releaseDate: DateTime(2023, 5, 13),
      imageUrl: 'https://images.ygoprodeck.com/images/sets/CYAC.jpg',
      cardsPerPack: 5,
      rarities: ['Common', 'Rare', 'Super Rare', 'Ultra Rare', 'Secret Rare'],
    ),
    PackSet(
      id: 'supreme-darkness',
      name: 'Duelist Nexus',
      code: 'DUNE',
      releaseDate: DateTime(2023, 7, 22),
      imageUrl: 'https://images.ygoprodeck.com/images/sets/DUNE.jpg',
      cardsPerPack: 5,
      rarities: ['Common', 'Rare', 'Super Rare', 'Ultra Rare', 'Secret Rare'],
    ),
    PackSet(
      id: 'crossover-breaker',
      name: 'Crossover Breakers',
      code: 'CROB',
      releaseDate: DateTime(2024, 12, 7),
      imageUrl: 'https://images.ygoprodeck.com/images/sets/CROB.jpg',
      cardsPerPack: 5,
      rarities: ['Common', 'Rare', 'Super Rare', 'Ultra Rare', 'Secret Rare'],
    ),
    PackSet(
      id: 'rage-abyss',
      name: 'Rage of the Abyss',
      code: 'ROTA',
      releaseDate: DateTime(2024, 11, 23),
      imageUrl: 'https://images.ygoprodeck.com/images/sets/ROTA.jpg',
      cardsPerPack: 5,
      rarities: ['Common', 'Rare', 'Super Rare', 'Ultra Rare', 'Secret Rare'],
    ),
    PackSet(
      id: 'infinite-forbidden',
      name: 'Infinite Forbidden',
      code: 'INFO',
      releaseDate: DateTime(2025, 2, 15),
      imageUrl: 'https://images.ygoprodeck.com/images/sets/INFO.jpg',
      cardsPerPack: 5,
      rarities: ['Common', 'Rare', 'Super Rare', 'Ultra Rare', 'Secret Rare'],
    ),
  ];

  List<PackOpening> _openingHistory = [];
  Map<String, List<YugiohCard>> _packCards = {}; // Cache kartu per pack
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

      // Pre-filter kartu untuk setiap pack
      for (var pack in _availablePacks) {
        _packCards[pack.code] = _filterCardsForPack(pack.code);
        debugPrint('📦 ${pack.code}: ${_packCards[pack.code]?.length ?? 0} cards available');
      }
    } catch (e) {
      debugPrint('❌ Error loading cards: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  List<YugiohCard> _filterCardsForPack(String packCode) {
    // Filter kartu yang memiliki set code yang sesuai
    return _allCards.where((card) {
      // Cek apakah kartu memiliki card_sets
      if (card.toJson()['card_sets'] == null) return false;

      final cardSets = card.toJson()['card_sets'] as List;

      // Cek apakah ada set yang sesuai dengan pack code
      return cardSets.any((set) {
        final setCode = set['set_code'] as String?;
        if (setCode == null) return false;

        // Match set code dengan pack code (case insensitive)
        return setCode.toUpperCase().startsWith(packCode.toUpperCase());
      });
    }).toList();
  }

  Future<PackOpening> openPack(PackSet pack) async {
    await loadCards();

    // Ambil kartu yang sesuai dengan pack
    List<YugiohCard> availableCards = _packCards[pack.code] ?? [];

    // Jika tidak ada kartu spesifik, gunakan random dari semua kartu
    if (availableCards.isEmpty) {
      debugPrint('⚠️ No specific cards found for ${pack.code}, using random cards');
      availableCards = _allCards;
    }

    if (availableCards.isEmpty) {
      throw Exception('No cards available');
    }

    final random = Random();
    final openedCards = <OpenedCard>[];

    // Simulasi pull rates
    for (int i = 0; i < pack.cardsPerPack; i++) {
      String rarity;

      final r = random.nextDouble();
      if (r < 0.01) {
        rarity = 'Secret Rare';
      } else if (r < 0.05) {
        rarity = 'Ultra Rare';
      } else if (r < 0.15) {
        rarity = 'Super Rare';
      } else if (r < 0.35) {
        rarity = 'Rare';
      } else {
        rarity = 'Common';
      }

      final card = availableCards[random.nextInt(availableCards.length)];
      openedCards.add(OpenedCard(
        cardId: card.id,
        name: card.name,
        imageUrl: card.imageUrl,
        rarity: rarity,
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
    switch (rarity) {
      case 'Quarter Century Secret':
        return 6;
      case 'Secret Rare':
        return 5;
      case 'Ultra Rare':
        return 4;
      case 'Super Rare':
        return 3;
      case 'Rare':
        return 2;
      case 'Common':
        return 1;
      default:
        return 0;
    }
  }

  Color getRarityColor(String rarity) {
    switch (rarity) {
      case 'Quarter Century Secret':
        return Colors.amber;
      case 'Secret Rare':
        return Colors.purple;
      case 'Ultra Rare':
        return Colors.yellow.shade700;
      case 'Super Rare':
        return Colors.blue;
      case 'Rare':
        return Colors.grey.shade300;
      case 'Common':
        return Colors.grey;
      default:
        return Colors.white;
    }
  }

  void clearHistory() {
    _openingHistory.clear();
    notifyListeners();
  }
}