class PackSet {
  final String id;
  final String name;
  final String code;
  final DateTime releaseDate;
  final String imageUrl;
  final int cardsPerPack;

  PackSet({
    required this.id,
    required this.name,
    required this.code,
    required this.releaseDate,
    required this.imageUrl,
    required this.cardsPerPack,
  });
}

class PackOpening {
  final String id;
  final PackSet pack;
  final List<OpenedCard> cards;
  final DateTime openedAt;

  PackOpening({
    required this.id,
    required this.pack,
    required this.cards,
    required this.openedAt,
  });
}

class OpenedCard {
  final int cardId;
  final String name;
  final String imageUrl;
  final String rarity;
  final String setCode;
  final bool isNew;

  OpenedCard({
    required this.cardId,
    required this.name,
    required this.imageUrl,
    required this.rarity,
    required this.setCode,
    this.isNew = false,
  });
}