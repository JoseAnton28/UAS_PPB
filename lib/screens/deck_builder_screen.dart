import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/deck_provider.dart';
import '../providers/card_provider.dart';
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
    if (!_tabController.indexIsChanging) {
      _filterCardsByTab();
    }
  }

  void _filterCardsByTab() {
    final cardProvider = context.read<CardProvider>();
    final allCards = cardProvider.searchResults;

    setState(() {
      if (_tabController.index == 1) {
        // Extra Deck
        _filteredCards =
            allCards.where((card) => _isExtraDeckCard(card)).toList();
      } else if (_tabController.index == 0) {
        // Main Deck
        _filteredCards =
            allCards.where((card) => !_isExtraDeckCard(card)).toList();
      } else {
        // Side Deck – semua kartu
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
              // ==== Kiri: Daftar kartu ====
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search cards...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          context.read<CardProvider>().filterLocalCards(value);
                          _filterCardsByTab();
                        },
                      ),
                    ),
                    // Info tab
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      color: Colors.purple.withAlpha(50),
                      child: Row(
                        children: [
                          Icon(
                            _tabController.index == 1
                                ? Icons.stars
                                : Icons.style,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _tabController.index == 1
                                  ? 'Extra Deck: Fusion, Synchro, Xyz, Link only'
                                  : _tabController.index == 0
                                  ? 'Main Deck: Monsters, Spells, Traps'
                                  : 'Side Deck: All cards available',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // List kartu
                    Expanded(
                      child: Consumer<CardProvider>(
                        builder: (context, cardProvider, child) {
                          if (cardProvider.isLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          return ListView.builder(
                            itemCount: _filteredCards.length,
                            itemBuilder: (context, index) {
                              final card = _filteredCards[index];
                              return _buildCardListItem(card, deckProvider);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ==== Kanan: Deck view ====
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
            color:
            deck.isValid ? Colors.green.shade900 : Colors.red.shade900,
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

  // -------------------------------------------------
  // Widget-widget pendukung
  // -------------------------------------------------

  Widget _buildCardListItem(YugiohCard card, DeckProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CachedNetworkImage(
          imageUrl: card.smallImageUrl,
          width: 40,
          fit: BoxFit.cover,
          placeholder: (_, __) => const SizedBox(
            width: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
        title: Text(card.name,
            style: const TextStyle(fontSize: 13), maxLines: 1),
        subtitle:
        Text(card.type, style: const TextStyle(fontSize: 10), maxLines: 1),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.green),
          onPressed: () {
            if (_tabController.index == 0) {
              provider.addCardToMainDeck(card);
            } else if (_tabController.index == 1) {
              provider.addCardToExtraDeck(card);
            } else {
              provider.addCardToSideDeck(card);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDeckSection(
      List<DeckCard> cards, DeckProvider provider, String deckType) {
    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              deckType == 'extra' ? Icons.stars : Icons.style,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text('No cards in ${deckType == 'main' ? 'Main' : deckType == 'extra' ? 'Extra' : 'Side'} Deck'),
          ],
        ),
      );
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
      itemBuilder: (context, index) {
        final deckCard = cards[index];
        return _buildDeckCardItem(deckCard, provider, deckType);
      },
    );
  }

  Widget _buildDeckCardItem(
      DeckCard deckCard, DeckProvider provider, String deckType) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: () => _showCardOptions(deckCard, provider, deckType),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: deckCard.card.smallImageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(Icons.error),
                  ),
                ),
                if (deckCard.quantity > 1)
                  Container(
                    color: Colors.black87,
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      'x${deckCard.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
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
                    provider.removeCardFromMainDeck(deckCard.card);
                  } else if (deckType == 'extra') {
                    provider.removeCardFromExtraDeck(deckCard.card);
                  } else {
                    provider.removeCardFromSideDeck(deckCard.card);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCardOptions(
      DeckCard deckCard, DeckProvider provider, String deckType) {
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
                if (deckType == 'main') {
                  provider.addCardToMainDeck(deckCard.card);
                } else if (deckType == 'extra') {
                  provider.addCardToExtraDeck(deckCard.card);
                } else {
                  provider.addCardToSideDeck(deckCard.card);
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove),
              title: const Text('Remove one'),
              onTap: () {
                if (deckType == 'main') {
                  provider.removeCardFromMainDeck(deckCard.card);
                } else if (deckType == 'extra') {
                  provider.removeCardFromExtraDeck(deckCard.card);
                } else {
                  provider.removeCardFromSideDeck(deckCard.card);
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------
  // Save Deck
  // -------------------------------------------------
  Future<void> _saveDeck(BuildContext context, DeckProvider deckProvider) async {
    final deck = deckProvider.currentDeck!;
    if (!deck.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deck must have 40-60 cards in Main Deck'),
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

    final success = await deckProvider.saveDeck(context);

    if (!context.mounted) return;
    Navigator.pop(context); // tutup loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deck saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // kembali ke daftar deck
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Save Failed'),
          content: Text(deckProvider.errorMessage.isNotEmpty
              ? deckProvider.errorMessage
              : 'Unknown error'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}