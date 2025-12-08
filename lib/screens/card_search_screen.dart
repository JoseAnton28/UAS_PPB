import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/card_provider.dart';
import '../models/card_model.dart';
import 'card_detail_screen.dart';

class CardSearchScreen extends StatefulWidget {
  const CardSearchScreen({super.key});

  @override
  State<CardSearchScreen> createState() => _CardSearchScreenState();
}

class _CardSearchScreenState extends State<CardSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCards();
  }

  Future<void> _initializeCards() async {
    final provider = context.read<CardProvider>();
    if (provider.allCards.isEmpty) {
      await provider.loadAllCards();
    }
    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Database'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search cards...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<CardProvider>().filterLocalCards('');
                  },
                ),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                context.read<CardProvider>().filterLocalCards(value);
              },
            ),
          ),
        ),
      ),
      body: Consumer<CardProvider>(
        builder: (context, provider, child) {
          if (!_isInitialized && provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeCards,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.searchResults.isEmpty) {
            return const Center(child: Text('No cards found'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: provider.searchResults.length,
            itemBuilder: (context, index) {
              final card = provider.searchResults[index];
              return _buildCardItem(card);
            },
          );
        },
      ),
    );
  }

  Widget _buildCardItem(YugiohCard card) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CardDetailScreen(card: card),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: card.smallImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                card.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}