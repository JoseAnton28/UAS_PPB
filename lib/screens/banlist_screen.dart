import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/banlist_provider.dart';
import '../models/card_model.dart';
import 'card_detail_screen.dart';

class BanlistScreen extends StatefulWidget {
  const BanlistScreen({super.key});
  @override State<BanlistScreen> createState() => _BanlistScreenState();
}

class _BanlistScreenState extends State<BanlistScreen> with SingleTickerProviderStateMixin {
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
            items: const [
              DropdownMenuItem(value: 'TCG', child: Text('TCG')),
              DropdownMenuItem(value: 'OCG', child: Text('OCG')),
            ],
            onChanged: (v) => context.read<BanlistProvider>().loadBanlist(v!.toLowerCase()),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(text: 'Forbidden'), Tab(text: 'Limited'), Tab(text: 'Semi-Limited')
        ]),
      ),
      body: Consumer<BanlistProvider>(
        builder: (context, p, _) {
          if (p.isLoading) return const Center(child: CircularProgressIndicator());
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
    if (cards.isEmpty) return const Center(child: Text('Tidak ada kartu'));

    final order = [
      'Normal Monster', 'Effect Monster', 'Ritual Monster', 'Pendulum Monster',
      'Fusion Monster', 'Synchro Monster', 'Xyz Monster', 'Link Monster',
      'Spell Card', 'Trap Card'
    ];

    cards.sort((a, b) {
      String getCleanType(String type) {
        if (type.contains('Tuner')) return 'Effect Monster';
        if (type.contains('Gemini')) return 'Effect Monster';
        if (type.contains('Spirit')) return 'Effect Monster';
        if (type.contains('Toon')) return 'Effect Monster';
        if (type.contains('Union')) return 'Effect Monster';
        return type;
      }

      final cleanA = getCleanType(a.type);
      final cleanB = getCleanType(b.type);

      final ia = order.indexWhere((t) => cleanA.contains(t));
      final ib = order.indexWhere((t) => cleanB.contains(t));
      return (ia == -1 ? 999 : ia).compareTo(ib == -1 ? 999 : ib);
    });

    return ListView.builder(
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final c = cards[i];
        String displayType = c.type;
        if (displayType.contains('Tuner') || displayType.contains('Gemini')) {
          displayType = 'Effect Monster';
        }

        return ListTile(
          leading: CachedNetworkImage(imageUrl: c.smallImageUrl, width: 40),
          title: Text(c.name),
          subtitle: Text(displayType.split(' ').first),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CardDetailScreen(card: c))),
        );
      },
    );
  }
}