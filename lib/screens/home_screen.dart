import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'card_search_screen.dart';
import 'deck_list_screen.dart';
import 'duel_simulator_screen.dart';
import 'match_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yu-Gi-Oh! Companion'),
        centerTitle: true,
        actions: [
          // User Profile & Logout
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle),
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    value: 'profile',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          authProvider.currentUser?.email ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout(context);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuCard(
              context,
              'Card Database',
              Icons.search,
              Colors.blue,
                  () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CardSearchScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              'Deck Builder',
              Icons.style,
              Colors.green,
                  () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeckListScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              'Duel Simulator',
              Icons.casino,
              Colors.red,
                  () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DuelSimulatorScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              'Match History',
              Icons.history,
              Colors.orange,
                  () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MatchHistoryScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    Future.delayed(Duration.zero, () async {
      await context.read<AuthProvider>().signOut();
    });
  }

  Widget _buildMenuCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}