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
      cardProvider.loadAllCards();
    } else {
      _filterCardsByTab();
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _filterCardsByTab();
    }
  }

  void _filterCardsByTab() {
    final cardProvider = context.read<CardProvider>();
    final allCards = cardProvider.searchResults;

    setState(() {
      if (_tabController.index == 1) {
        // Extra Deck tab - hanya Fusion, Synchro, Xyz, Link
        _filteredCards = allCards.where((card) => _isExtraDeckCard(card)).toList();
      } else {
        // Main Deck & Side Deck tabs - tampilkan SEMUA kartu
        _filteredCards = allCards;
      }
    });
  }

  bool _isExtraDeckCard(YugiohCard card) {
    return card.type.contains('Fusion') ||
        card.type.contains('Synchro') ||
        card.type.contains('Xyz') ||
        card.type.contains('Link');
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
              // Card list section
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          context.read<CardProvider>().filterLocalCards(value);
                          _filterCardsByTab();
                        },
                      ),
                    ),
                    // Tab info
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: Colors.purple.withOpacity(0.2),
                      child: Row(
                        children: [
                          Icon(
                            _tabController.index == 1 ? Icons.stars : Icons.style,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _tabController.index == 1
                                  ? 'Extra Deck: Fusion, Synchro, Xyz, Link only'
                                  : _tabController.index == 0
                                  ? 'Main Deck: All cards available'
                                  : 'Side Deck: All cards available',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Consumer<CardProvider>(
                        builder: (context, cardProvider, child) {
                          if (cardProvider.isLoading) {
                            return const Center(child: CircularProgressIndicator());
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

              // Deck view section
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
                  ? 'Deck is valid! ✓'
                  : 'Deck must have 40-60 cards in main deck',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveDeck(BuildContext context, DeckProvider deckProvider) async {
    final deck = deckProvider.currentDeck;

    if (deck == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No deck to save'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi deck
    if (!deck.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deck must have 40-60 cards in Main Deck'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await deckProvider.saveDeck();

    if (!context.mounted) return;
    Navigator.pop(context); // Close loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Deck saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context); // Back to deck list
    } else {
      // Show detailed error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save Failed'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Failed to save deck.'),
                const SizedBox(height: 8),
                const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  deckProvider.errorMessage,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
                const SizedBox(height: 16),
                const Text('Possible solutions:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('• Check your internet connection'),
                const Text('• Make sure you are logged in'),
                const Text('• Try logging out and back in'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCardListItem(YugiohCard card, DeckProvider deckProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CachedNetworkImage(
          imageUrl: card.smallImageUrl,
          width: 40,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox(
            width: 40,
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
        title: Text(
          card.name,
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          card.type,
          style: const TextStyle(fontSize: 10),
          maxLines: 1,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.green),
          onPressed: () {
            // Add to current tab WITHOUT snackbar
            if (_tabController.index == 0) {
              deckProvider.addCardToMainDeck(card);
            } else if (_tabController.index == 1) {
              deckProvider.addCardToExtraDeck(card);
            } else {
              deckProvider.addCardToSideDeck(card);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDeckSection(
      List<DeckCard> cards,
      DeckProvider provider,
      String deckType,
      ) {
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
            Text(
              'No cards in ${deckType == 'main' ? 'Main' : deckType == 'extra' ? 'Extra' : 'Side'} Deck',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Add cards from the list on the left',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
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
      DeckCard deckCard,
      DeckProvider provider,
      String deckType,
      ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              _showCardOptions(deckCard, provider, deckType);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: deckCard.card.smallImageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(Icons.error),
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
                icon: const Icon(Icons.close),
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
      DeckCard deckCard,
      DeckProvider provider,
      String deckType,
      ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
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

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}