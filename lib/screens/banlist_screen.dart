import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/banlist_provider.dart';
import '../models/card_model.dart';
import 'card_detail_screen.dart';

class BanlistScreen extends StatefulWidget {
  const BanlistScreen({super.key});
  @override
  State<BanlistScreen> createState() => _BanlistScreenState();
}

class _BanlistScreenState extends State<BanlistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<BanlistProvider>().loadBanlist('tcg');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banlist'),
        actions: [
          DropdownButton<String>(
            value: context.watch<BanlistProvider>().format.toUpperCase(),
            dropdownColor: Colors.black87,
            items: const [
              DropdownMenuItem(value: 'TCG', child: Text('TCG')),
              DropdownMenuItem(value: 'OCG', child: Text('OCG')),
            ],
            onChanged: (v) =>
                context.read<BanlistProvider>().loadBanlist(v!.toLowerCase()),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Forbidden'),
            Tab(text: 'Limited'),
            Tab(text: 'Semi-Limited')
          ],
        ),
      ),
      body: Consumer<BanlistProvider>(
        builder: (context, p, _) {
          if (p.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final lists = [p.forbidden, p.limited, p.semiLimited];
          return TabBarView(
            controller: _tabController,
            children: lists.map((cards) => _buildSortedList(cards)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSortedList(List<YugiohCard> cards) {
    if (cards.isEmpty) {
      return const Center(child: Text('Tidak ada kartu'));
    }

    final order = [
      'Normal Monster',
      'Effect Monster',
      'Ritual Monster',
      'Pendulum Monster',
      'Fusion Monster',
      'Synchro Monster',
      'Xyz Monster',
      'Link Monster',
      'Spell Card',
      'Trap Card'
    ];

    cards.sort((a, b) {
      String fix(String t) {
        if (t.contains('Tuner') ||
            t.contains('Gemini') ||
            t.contains('Spirit') ||
            t.contains('Toon') ||
            t.contains('Union')) {
          return 'Effect Monster';
        }
        return t;
      }

      final ia = order.indexWhere((t) => fix(a.type).contains(t));
      final ib = order.indexWhere((t) => fix(b.type).contains(t));
      return (ia == -1 ? 999 : ia).compareTo(ib == -1 ? 999 : ib);
    });

    return ListView.builder(
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final c = cards[i];
        final displayType = c.type.contains('Tuner') || c.type.contains('Gemini')
            ? 'Effect Monster'
            : c.type;

        return TweenAnimationBuilder(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, value, child) => Transform.translate(
            offset: Offset(0, 22 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          ),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CardDetailScreen(card: c),
              ),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withOpacity(0.28),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: c.smallImageUrl,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          displayType.split(" ").first,
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
