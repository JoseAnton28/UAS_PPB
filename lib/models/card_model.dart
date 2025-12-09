import 'package:flutter/foundation.dart';

class YugiohCard {
  final int id;
  final String name;
  final String type;
  final String desc;
  final int? atk;
  final int? def;
  final int? level;
  final String? race;
  final String? attribute;
  final List<CardImage> cardImages;
  final String? archetype;
  final Map<String, dynamic>? banlistInfo;
  final List<CardSet>? cardSets; // TAMBAHAN BARU untuk pack filtering

  YugiohCard({
    required this.id,
    required this.name,
    required this.type,
    required this.desc,
    this.atk,
    this.def,
    this.level,
    this.race,
    this.attribute,
    required this.cardImages,
    this.archetype,
    this.banlistInfo,
    this.cardSets, // TAMBAHAN BARU
  });

  factory YugiohCard.fromJson(Map<String, dynamic> json) {
    return YugiohCard(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      desc: json['desc'],
      atk: json['atk'],
      def: json['def'],
      level: json['level'],
      race: json['race'],
      attribute: json['attribute'],
      cardImages: (json['card_images'] as List)
          .map((img) => CardImage.fromJson(img))
          .toList(),
      archetype: json['archetype'],
      banlistInfo: json['banlist_info'] as Map<String, dynamic>?,
      // TAMBAHAN BARU: Parse card_sets
      cardSets: json['card_sets'] != null
          ? (json['card_sets'] as List)
          .map((set) => CardSet.fromJson(set))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'desc': desc,
      'atk': atk,
      'def': def,
      'level': level,
      'race': race,
      'attribute': attribute,
      'archetype': archetype,
      'card_images': cardImages.map((img) => {
        'id': img.id,
        'image_url': img.imageUrl,
        'image_url_small': img.imageUrlSmall,
      }).toList(),
      'banlist_info': banlistInfo,
      // TAMBAHAN BARU: Include card_sets
      'card_sets': cardSets?.map((set) => set.toJson()).toList(),
    };
  }

  String get imageUrl => cardImages.isNotEmpty ? cardImages[0].imageUrl : '';
  String get smallImageUrl => cardImages.isNotEmpty ? cardImages[0].imageUrlSmall : '';
}

class CardImage {
  final int id;
  final String imageUrl;
  final String imageUrlSmall;

  CardImage({
    required this.id,
    required this.imageUrl,
    required this.imageUrlSmall,
  });

  factory CardImage.fromJson(Map<String, dynamic> json) {
    return CardImage(
      id: json['id'],
      imageUrl: json['image_url'],
      imageUrlSmall: json['image_url_small'],
    );
  }
}

// TAMBAHAN BARU: Model untuk card set
class CardSet {
  final String setName;
  final String setCode;
  final String setRarity;
  final String setRarityCode;
  final String setPrice;

  CardSet({
    required this.setName,
    required this.setCode,
    required this.setRarity,
    required this.setRarityCode,
    required this.setPrice,
  });

  factory CardSet.fromJson(Map<String, dynamic> json) {
    return CardSet(
      setName: json['set_name'] ?? '',
      setCode: json['set_code'] ?? '',
      setRarity: json['set_rarity'] ?? '',
      setRarityCode: json['set_rarity_code'] ?? '',
      setPrice: json['set_price'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'set_name': setName,
      'set_code': setCode,
      'set_rarity': setRarity,
      'set_rarity_code': setRarityCode,
      'set_price': setPrice,
    };
  }
}

class DeckCard {
  final YugiohCard card;
  int quantity;

  DeckCard({required this.card, this.quantity = 1});

  Map<String, dynamic> toJson() {
    return {
      'card': card.toJson(),
      'quantity': quantity,
    };
  }
}

class Deck {
  dynamic id;
  String name;
  List<DeckCard> mainDeck;
  List<DeckCard> extraDeck;
  List<DeckCard> sideDeck;
  DateTime createdAt;
  DateTime updatedAt;

  Deck({
    this.id,
    required this.name,
    required this.mainDeck,
    required this.extraDeck,
    required this.sideDeck,
    required this.createdAt,
    required this.updatedAt,
  });

  int get mainDeckCount => mainDeck.fold(0, (sum, card) => sum + card.quantity);
  int get extraDeckCount => extraDeck.fold(0, (sum, card) => sum + card.quantity);
  int get sideDeckCount => sideDeck.fold(0, (sum, card) => sum + card.quantity);

  bool get isValid => mainDeckCount >= 40 && mainDeckCount <= 60 && extraDeckCount <= 15 && sideDeckCount <= 15;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mainDeck': mainDeck.map((c) => c.toJson()).toList(),
      'extraDeck': extraDeck.map((c) => c.toJson()).toList(),
      'sideDeck': sideDeck.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class MatchHistory {
  dynamic id;
  String player1Name;
  String player2Name;
  int player1LP;
  int player2LP;
  String winner;
  DateTime matchDate;
  int durationMinutes;

  MatchHistory({
    this.id,
    required this.player1Name,
    required this.player2Name,
    required this.player1LP,
    required this.player2LP,
    required this.winner,
    required this.matchDate,
    required this.durationMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'player1Name': player1Name,
      'player2Name': player2Name,
      'player1LP': player1LP,
      'player2LP': player2LP,
      'winner': winner,
      'matchDate': matchDate.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }

  factory MatchHistory.fromMap(Map<String, dynamic> map) {
    return MatchHistory(
      id: map['id'],
      player1Name: map['player1Name'],
      player2Name: map['player2Name'],
      player1LP: map['player1LP'],
      player2LP: map['player2LP'],
      winner: map['winner'],
      matchDate: DateTime.parse(map['matchDate']),
      durationMinutes: map['durationMinutes'],
    );
  }
}