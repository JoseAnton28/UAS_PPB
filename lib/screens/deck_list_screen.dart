import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/deck_provider.dart';
import 'deck_builder_screen.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DeckProvider>().loadDecks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Decks'),
      ),
      body: Consumer<DeckProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.decks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.style, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No decks yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _createNewDeck(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Deck'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.decks.length,
            itemBuilder: (context, index) {
              final deck = provider.decks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.style),
                  ),
                  title: Text(
                    deck.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Main: ${deck.mainDeckCount} | Extra: ${deck.extraDeckCount} | Side: ${deck.sideDeckCount}'),
                      Text(
                        'Updated: ${DateFormat('MMM dd, yyyy').format(deck.updatedAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!deck.isValid)
                        const Icon(Icons.warning, color: Colors.orange),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteDeck(context, deck.id!),
                      ),
                    ],
                  ),
                  onTap: () {
                    provider.setCurrentDeck(deck);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DeckBuilderScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewDeck(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createNewDeck(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Deck'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Deck Name',
            hintText: 'Enter deck name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<DeckProvider>().createNewDeck(controller.text);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeckBuilderScreen(),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _deleteDeck(BuildContext context, dynamic id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deck'),
        content: const Text('Are you sure you want to delete this deck?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<DeckProvider>().deleteDeck(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}