import 'package:flutter/foundation.dart';
import '../models/card_model.dart';
import '../services/api_service.dart';

class BanlistProvider extends ChangeNotifier {
  List<YugiohCard> _forbidden = [];
  List<YugiohCard> _limited = [];
  List<YugiohCard> _semiLimited = [];
  bool _isLoading = false;
  String _format = 'tcg';

  List<YugiohCard> get forbidden => _forbidden;
  List<YugiohCard> get limited => _limited;
  List<YugiohCard> get semiLimited => _semiLimited;
  bool get isLoading => _isLoading;
  String get format => _format;

  Future<void> loadBanlist(String format) async {
    _isLoading = true;
    _format = format.toLowerCase();
    notifyListeners();

    try {
      final cards = await ApiService.getBanlistCards(_format);
      _forbidden = cards.where((c) => getStatus(c) == 'forbidden').toList();
      _limited = cards.where((c) => getStatus(c) == 'limited').toList();
      _semiLimited = cards.where((c) => getStatus(c) == 'semi_limited').toList();
    } catch (e) {
      debugPrint('Banlist load error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  String getStatus(YugiohCard card) {
    final info = card.banlistInfo;
    if (info == null) return 'unlimited';
    final status = _format == 'tcg' ? info['ban_tcg'] : info['ban_ocg'];
    if (status == null) return 'unlimited';
    final s = status.toString().toLowerCase();
    if (s.contains('forbidden')) return 'forbidden';
    if (s.contains('limited') && !s.contains('semi')) return 'limited';
    if (s.contains('semi')) return 'semi_limited';
    return 'unlimited';
  }

  Map<String, dynamic> validateDeck(Deck deck) {
    final issues = <String>[];
    final Map<int, int> countMap = {};

    for (var dc in [...deck.mainDeck, ...deck.extraDeck, ...deck.sideDeck]) {
      countMap[dc.card.id] = (countMap[dc.card.id] ?? 0) + dc.quantity;
    }

    for (var entry in countMap.entries) {
      final cardId = entry.key;
      final qty = entry.value;
      final card = deck.mainDeck.firstWhereOrNull((dc) => dc.card.id == cardId)?.card ??
          deck.extraDeck.firstWhereOrNull((dc) => dc.card.id == cardId)?.card ??
          deck.sideDeck.firstWhereOrNull((dc) => dc.card.id == cardId)?.card;

      if (card == null) continue;
      final status = getStatus(card);
      if (status == 'forbidden' && qty > 0) issues.add('${card.name} Forbidden');
      if (status == 'limited' && qty > 1) issues.add('${card.name} Limited (max 1)');
      if (status == 'semi_limited' && qty > 2) issues.add('${card.name} Semi-Limited (max 2)');
    }

    return {'valid': issues.isEmpty, 'issues': issues};
  }
}

extension FirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) if (test(element)) return element;
    return null;
  }
}