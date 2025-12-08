import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/duel_provider.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DuelProvider>().loadMatchHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match History'),
      ),
      body: Consumer<DuelProvider>(
        builder: (context, provider, child) {
          if (provider.matchHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No matches recorded yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Play some duels and save them!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.matchHistory.length,
            itemBuilder: (context, index) {
              final match = provider.matchHistory[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getWinnerColor(
                      match.winner,
                      match.player1Name,
                    ),
                    child: const Icon(Icons.emoji_events, color: Colors.white),
                  ),
                  title: Text(
                    '${match.player1Name} vs ${match.player2Name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy - HH:mm').format(match.matchDate),
                    style: const TextStyle(fontSize: 12),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPlayerStats(
                                match.player1Name,
                                match.player1LP,
                                match.winner == match.player1Name,
                              ),
                              const Icon(Icons.compare_arrows, size: 32),
                              _buildPlayerStats(
                                match.player2Name,
                                match.player2LP,
                                match.winner == match.player2Name,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Winner',
                                match.winner,
                                Icons.emoji_events,
                              ),
                              _buildStatItem(
                                'Duration',
                                '${match.durationMinutes} min',
                                Icons.timer,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _deleteMatch(context, match.id!),
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete Match'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPlayerStats(String name, int lp, bool isWinner) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
            color: isWinner ? Colors.green : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$lp LP',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: lp > 0 ? Colors.green : Colors.red,
          ),
        ),
        if (isWinner)
          const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getWinnerColor(String winner, String player1Name) {
    if (winner == player1Name) {
      return Colors.blue;
    } else if (winner == 'Draw') {
      return Colors.grey;
    } else {
      return Colors.red;
    }
  }

  void _deleteMatch(BuildContext context, dynamic id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Match'),
        content: const Text('Are you sure you want to delete this match record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<DuelProvider>().deleteMatch(id);
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