import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../providers/card_provider.dart';

class CardDetailScreen extends StatefulWidget {
  final YugiohCard card;

  const CardDetailScreen({super.key, required this.card});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final isFav = await context.read<CardProvider>().isFavorite(widget.card.id);
    setState(() => _isFavorite = isFav);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card.name),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () async {
              await context.read<CardProvider>().toggleFavorite(widget.card);
              _checkFavorite();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: CachedNetworkImage(
                  imageUrl: widget.card.imageUrl,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard('Name', widget.card.name),
            _buildInfoCard('Type', widget.card.type),
            if (widget.card.attribute != null)
              _buildInfoCard('Attribute', widget.card.attribute!),
            if (widget.card.race != null)
              _buildInfoCard('Race', widget.card.race!),
            if (widget.card.level != null)
              _buildInfoCard('Level', widget.card.level.toString()),
            if (widget.card.atk != null)
              _buildInfoCard('ATK', widget.card.atk.toString()),
            if (widget.card.def != null)
              _buildInfoCard('DEF', widget.card.def.toString()),
            if (widget.card.archetype != null)
              _buildInfoCard('Archetype', widget.card.archetype!),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.card.desc,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}