// lib/screens/card_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/card_model.dart';

class CardDetailScreen extends StatefulWidget {
  final YugiohCard card;

  const CardDetailScreen({super.key, required this.card});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _imageController;
  late Animation<double> _imageScale;

  late AnimationController _listController;

  @override
  void initState() {
    super.initState();

    // Animasi gambar
    _imageController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _imageScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _imageController, curve: Curves.easeOutBack),
    );
    _imageController.forward();

    // Animasi card muncul berurutan
    _listController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _listController.forward();
  }

  @override
  void dispose() {
    _imageController.dispose();
    _listController.dispose();
    super.dispose();
  }

  // animasi tiap info card
  Widget _animatedItem(int index, Widget child) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1)
          .animate(CurvedAnimation(parent: _listController, curve: Interval(index * 0.1, 1))),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(CurvedAnimation(parent: _listController, curve: Interval(index * 0.1, 1))),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    int index = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          card.name,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // image animated
            Center(
              child: ScaleTransition(
                scale: _imageScale,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 350),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: card.imageUrl,
                      placeholder: (context, url) => const Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      errorWidget: (context, url, error) => const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          SizedBox(height: 8),
                          Text('Image failed to load'),
                        ],
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _animatedItem(index++, _buildInfoCard('Name', card.name)),
            _animatedItem(index++, _buildInfoCard('Type', card.type)),
            if (card.attribute != null)
              _animatedItem(index++, _buildInfoCard('Attribute', card.attribute!)),
            if (card.race != null)
              _animatedItem(index++, _buildInfoCard('Race / Type', card.race!)),
            if (card.level != null)
              _animatedItem(index++, _buildInfoCard('Level / Rank / Link', card.level.toString())),
            if (card.atk != null)
              _animatedItem(index++, _buildInfoCard('ATK', card.atk.toString())),
            if (card.def != null && !card.type.contains('Link'))
              _animatedItem(index++, _buildInfoCard('DEF', card.def.toString())),
            if (card.archetype != null)
              _animatedItem(index++, _buildInfoCard('Archetype', card.archetype!)),

            const SizedBox(height: 20),

            // description animated
            _animatedItem(
              index++,
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Card Effect',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        card.desc,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}