import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/deck_provider.dart';
import '../providers/card_provider.dart';
import '../providers/banlist_provider.dart';
import '../models/card_model.dart';

class DeckBuilderScreen extends StatefulWidget {
  const DeckBuilderScreen({super.key});

  @override
  State<DeckBuilderScreen> createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends State<DeckBuilderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<YugiohCard> _filteredCards = [];

  @override
  void initState() {
    super.initState();

    // 🔥 Paksa Landscape saat masuk Deck Builder
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadCards();
  }

  void _loadCards() {
    final cardProvider = context.read<CardProvider>();
    if (cardProvider.allCards.isEmpty) {
      cardProvider.loadAllCards().then((_) => _filterCardsByTab());
    } else {
      _filterCardsByTab();
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) _filterCardsByTab();
  }

  void _filterCardsByTab() {
    final allCards = context.read<CardProvider>().searchResults;
    setState(() {
      if (_tabController.index == 1) {
        _filteredCards = allCards.where((c) => _isExtraDeckCard(c)).toList();
      } else if (_tabController.index == 0) {
        _filteredCards = allCards.where((c) => !_isExtraDeckCard(c)).toList();
      } else {
        _filteredCards = allCards;
      }
    });
  }

  bool _isExtraDeckCard(YugiohCard card) {
    final type = card.type.toLowerCase();
    return type.contains('fusion') ||
        type.contains('synchro') ||
        type.contains('xyz') ||
        type.contains('link');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeckProvider>(
      builder: (context, deckProvider, child) {
        final deck = deckProvider.currentDeck;
        if (deck == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Deck Builder')),
            body: const Center(child: Text('No deck selected')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(deck.name),
            actions: [
              DropdownButton<String>(
                value: deckProvider.selectedBanlist,
                dropdownColor: Colors.grey[900],
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('No Banlist')),
                  DropdownMenuItem(value: 'tcg', child: Text('TCG Banlist')),
                  DropdownMenuItem(value: 'ocg', child: Text('OCG Banlist')),
                ],
                onChanged: (v) => v != null ? deckProvider.setBanlistFormat(v) : null,
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => _saveDeck(context, deckProvider),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Main (${deck.mainDeckCount}/60)'),
                Tab(text: 'Extra (${deck.extraDeckCount}/15)'),
                Tab(text: 'Side (${deck.sideDeckCount}/15)'),
              ],
            ),
          ),
          body: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search cards...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (v) {
                          context.read<CardProvider>().filterLocalCards(v);
                          _filterCardsByTab();
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: Colors.purple.withAlpha(50),
                      child: Row(
                        children: [
                          Icon(
                              _tabController.index == 1
                                  ? Icons.stars
                                  : Icons.style,
                              size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _tabController.index == 1
                                  ? 'Extra Deck only'
                                  : _tabController.index == 0
                                  ? 'Main Deck'
                                  : 'Side Deck',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Consumer<CardProvider>(
                        builder: (context, cp, _) {
                          if (cp.isLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          return GridView.builder(
                            padding: const EdgeInsets.all(6),
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4, // 🔥 muat banyak kartu
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: _filteredCards.length,
                            itemBuilder: (_, i) {
                              final YugiohCard card = _filteredCards[i];
                              final banStatus = deckProvider.selectedBanlist != 'none'
                                  ? context.read<BanlistProvider>().getStatus(card)
                                  : 'unlimited';

                              return GestureDetector(
                                onTap: () {
                                  if (_tabController.index == 0) {
                                    deckProvider.addCardToMainDeck(card, context);
                                  } else if (_tabController.index == 1) {
                                    deckProvider.addCardToExtraDeck(card, context);
                                  } else {
                                    deckProvider.addCardToSideDeck(card, context);
                                  }
                                },
                                child: Stack(
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: card.smallImageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(color: Colors.black12),
                                    ),
                                    if (banStatus != 'unlimited')
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: CircleAvatar(
                                          radius: 10,
                                          backgroundColor: banStatus == 'forbidden'
                                              ? Colors.red
                                              : banStatus == 'limited'
                                              ? Colors.orange
                                              : Colors.yellow,
                                          child: Text(
                                            banStatus == 'forbidden'
                                                ? 'X'
                                                : banStatus == 'limited'
                                                ? '1'
                                                : '2',
                                            style: const TextStyle(
                                                fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                flex: 3,
                child: Container(
                  color: const Color(0xFF16213e),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDeckSection(deck.mainDeck, deckProvider, 'main'),
                      _buildDeckSection(deck.extraDeck, deckProvider, 'extra'),
                      _buildDeckSection(deck.sideDeck, deckProvider, 'side'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(8),
            color: deck.isValid ? Colors.green.shade900 : Colors.red.shade900,
            child: Text(
              deck.isValid
                  ? 'Deck is valid!'
                  : 'Main Deck must have 40-60 cards',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardListItem(YugiohCard card, DeckProvider provider) {
    final banStatus = provider.selectedBanlist != 'none'
        ? context.read<BanlistProvider>().getStatus(card)
        : 'unlimited';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CachedNetworkImage(imageUrl: card.smallImageUrl, width: 40),
            if (banStatus == 'forbidden')
              _banIcon("X", Colors.red),
            if (banStatus == 'limited')
              _banIcon("1", Colors.orange),
            if (banStatus == 'semi_limited')
              _banIcon("2", Colors.yellow),
          ],
        ),

        // 🔥 Tidak vertikal & auto "..."
        title: Row(
          children: [
            Expanded(
              child: Text(
                card.name,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),

        trailing: IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
          onPressed: () {
            if (_tabController.index == 0) {
              provider.addCardToMainDeck(card, context);
            } else if (_tabController.index == 1) {
              provider.addCardToExtraDeck(card, context);
            } else {
              provider.addCardToSideDeck(card, context);
            }
          },
        ),
      ),
    );
  }

  Widget _banIcon(String text, Color color) {
    return Positioned(
      top: 0,
      right: 0,
      child: CircleAvatar(
        radius: 9,
        backgroundColor: color,
        child: Text(text,
            style: const TextStyle(fontSize: 10, color: Colors.white)),
      ),
    );
  }

  Widget _buildDeckSection(List<DeckCard> cards, DeckProvider provider, String deckType) {
    if (cards.isEmpty) {
      return Center(child: Text('No cards in $deckType Deck'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _buildDeckCardItem(cards[i], provider, deckType),
    );
  }

  Widget _buildDeckCardItem(DeckCard dc, DeckProvider provider, String deckType) {
    final banStatus = provider.selectedBanlist != 'none'
        ? context.read<BanlistProvider>().getStatus(dc.card)
        : 'unlimited';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: () => _showCardOptions(dc, provider, deckType),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: dc.card.smallImageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(Icons.error),
                  ),
                ),
                if (dc.quantity > 1)
                  Container(
                    color: Colors.black87,
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      'x${dc.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          if (banStatus != 'unlimited')
            Positioned(
              top: 4,
              left: 4,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: banStatus == 'forbidden'
                    ? Colors.red
                    : banStatus == 'limited'
                    ? Colors.orange
                    : Colors.yellow,
                child: Text(
                  banStatus == 'forbidden'
                      ? 'X'
                      : banStatus == 'limited'
                      ? '1'
                      : '2',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  if (deckType == 'main') {
                    provider.removeCardFromMainDeck(dc.card);
                  } else if (deckType == 'extra') {
                    provider.removeCardFromExtraDeck(dc.card);
                  } else {
                    provider.removeCardFromSideDeck(dc.card);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCardOptions(DeckCard dc, DeckProvider p, String type) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add one more'),
              onTap: () {
                if (type == 'main') p.addCardToMainDeck(dc.card, context);
                else if (type == 'extra') p.addCardToExtraDeck(dc.card, context);
                else p.addCardToSideDeck(dc.card, context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove),
              title: const Text('Remove one'),
              onTap: () {
                if (type == 'main') p.removeCardFromMainDeck(dc.card);
                else if (type == 'extra') p.removeCardFromExtraDeck(dc.card);
                else p.removeCardFromSideDeck(dc.card);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDeck(BuildContext context, DeckProvider dp) async {
    final deck = dp.currentDeck!;
    if (!deck.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Main Deck harus 40-60 kartu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await dp.saveDeck(context);
    if (!context.mounted) return;
    Navigator.pop(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deck saved!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Save Failed'),
          content: Text(dp.errorMessage),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    // 🔥 Kembalikan portrait saat keluar dari deck builder
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}