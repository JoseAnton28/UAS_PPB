// lib/screens/pack_opening_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/pack_provider.dart';
import '../models/pack_model.dart';

class PackOpeningScreen extends StatefulWidget {
  const PackOpeningScreen({super.key});

  @override
  State<PackOpeningScreen> createState() => _PackOpeningScreenState();
}

class _PackOpeningScreenState extends State<PackOpeningScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
    Future.microtask(() => context.read<PackProvider>().loadCards());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pack Opening Simulator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
          ),
        ],
      ),
      body: Consumer<PackProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading card database...'),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.card_giftcard, size: 64, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'Pack Opening Simulator',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${provider.availablePacks.length} OCG Main Sets',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pack Grid
              ...provider.availablePacks.asMap().entries.map((entry) {
                final index = entry.key;
                final pack = entry.value;
                return _buildPackCard(pack, index);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPackCard(PackSet pack, int index) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(index * 0.15, 1, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openPack(pack),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Pack Image
                  Hero(
                    tag: 'pack-${pack.id}',
                    child: Container(
                      width: 80,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: pack.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(Icons.card_giftcard, size: 40),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.broken_image, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Pack Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pack.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pack.code,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${pack.releaseDate.year}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.style, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${pack.cardsPerPack} cards',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Open Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.purple],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'OPEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPack(PackSet pack) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final provider = context.read<PackProvider>();
      final opening = await provider.openPack(pack);

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PackAnimationScreen(opening: opening),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showHistory(BuildContext context) {
    final provider = context.read<PackProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1a1a2e),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Opening History',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (provider.openingHistory.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          provider.clearHistory();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: provider.openingHistory.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No packs opened yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.openingHistory.length,
                  itemBuilder: (context, index) {
                    final opening = provider.openingHistory[index];
                    return _buildHistoryCard(opening);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(PackOpening opening) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: opening.pack.imageUrl,
                    width: 40,
                    height: 55,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opening.pack.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${opening.openedAt.hour}:${opening.openedAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: opening.cards.map((card) {
                final color = context.read<PackProvider>().getRarityColor(card.rarity);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    border: Border.all(color: color),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    card.rarity.split(' ').first,
                    style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PACK ANIMATION SCREEN - TAP TO REVEAL
// ============================================================================

class PackAnimationScreen extends StatefulWidget {
  final PackOpening opening;

  const PackAnimationScreen({super.key, required this.opening});

  @override
  State<PackAnimationScreen> createState() => _PackAnimationScreenState();
}

class _PackAnimationScreenState extends State<PackAnimationScreen>
    with TickerProviderStateMixin {
  late AnimationController _packController;
  late AnimationController _cardController;
  late Animation<double> _packScale;
  late Animation<double> _packOpacity;
  late Animation<double> _cardScale;
  late Animation<double> _cardRotation;

  int _currentCardIndex = 0;
  bool _showingCards = false;

  @override
  void initState() {
    super.initState();

    // Pack animation
    _packController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _packScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _packController, curve: Curves.easeOut),
    );

    _packOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _packController, curve: const Interval(0.7, 1.0)),
    );

    // Card reveal animation
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _cardScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );

    _cardRotation = Tween<double>(begin: -0.3, end: 0.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOut),
    );

    _startPackAnimation();
  }

  Future<void> _startPackAnimation() async {
    await _packController.forward();
    if (mounted) {
      setState(() => _showingCards = true);
    }
  }

  void _revealNextCard() {
    if (_currentCardIndex >= widget.opening.cards.length) return;

    setState(() => _currentCardIndex++);
    _cardController.forward(from: 0);
  }

  @override
  void dispose() {
    _packController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    widget.opening.pack.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Center(
                child: !_showingCards
                    ? _buildPackAnimation()
                    : _buildCardReveal(),
              ),
            ),

            // Bottom controls
            if (_showingCards)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.opening.cards.length,
                            (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < _currentCardIndex
                                ? Colors.yellow
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tap instruction
                    if (_currentCardIndex < widget.opening.cards.length)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'TAP TO REVEAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackAnimation() {
    return AnimatedBuilder(
      animation: _packController,
      builder: (context, child) {
        return Transform.scale(
          scale: _packScale.value,
          child: Opacity(
            opacity: _packOpacity.value,
            child: Hero(
              tag: 'pack-${widget.opening.pack.id}',
              child: Container(
                width: 200,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: widget.opening.pack.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardReveal() {
    if (_currentCardIndex == 0) {
      return GestureDetector(
        onTap: _revealNextCard,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
          child: const Center(
            child: Icon(Icons.touch_app, color: Colors.white54, size: 80),
          ),
        ),
      );
    }

    final card = widget.opening.cards[_currentCardIndex - 1];
    final provider = context.read<PackProvider>();
    final rarityColor = provider.getRarityColor(card.rarity);

    return GestureDetector(
        onTap: _currentCardIndex < widget.opening.cards.length
            ? _revealNextCard
            : null,
        child: AnimatedBuilder(
            animation: _cardController,
            builder: (context, child) {
              return Transform.scale(
                scale: _cardScale.value,
                child: Transform.rotate(
                  angle: _cardRotation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Card image
                      Container(
                        width: 280,
                        height: 400,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: rarityColor.withOpacity(0.6),
                              blurRadius: 40,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CachedNetworkImage(
                                imageUrl: card.imageUrl,
                                fit: BoxFit.contain,
                                placeholder: (_, __) =>
                                    Container(
                                      color: Colors.grey[900],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                              ),
                            ),
                            if (card.isNew)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.orange, Colors.red],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Card name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          card.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Rarity badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: rarityColor.withOpacity(0.2),
                          border: Border.all(color: rarityColor, width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          card.rarity.toUpperCase(),
                          style: TextStyle(
                            color: rarityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Set code
                      if (card.setCode.isNotEmpty)
                        Text(
                          card.setCode,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Counter
                      Text(
                        '$_currentCardIndex / ${widget.opening.cards.length}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
              )
              );
            }
            }