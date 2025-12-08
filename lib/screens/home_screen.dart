import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'card_search_screen.dart';
import 'deck_list_screen.dart';
import 'duel_simulator_screen.dart';
import 'match_history_screen.dart';
import 'login_screen.dart'; // Pastikan import ini ada

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yu-Gi-Oh! Companion'),
        centerTitle: true,
        elevation: 2,
        actions: [
          // Profile & Logout Button
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                tooltip: 'Account',
                icon: const Icon(Icons.account_circle, size: 28),
                itemBuilder: (context) => [
                  // User Info (tidak bisa diklik)
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authProvider.currentUser?.email ?? 'user@email.com',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  // Logout Button
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: const [
                        Icon(Icons.logout, color: Colors.redAccent),
                        SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(color: Colors.redAccent),
                        ),
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
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.1,
          children: [
            _buildMenuCard(
              context,
              title: 'Card Database',
              icon: Icons.search,
              color: Colors.blueAccent,
              gradient: const LinearGradient(
                colors: [Colors.blueAccent, Colors.indigo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CardSearchScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              title: 'Deck Builder',
              icon: Icons.style,
              color: Colors.green,
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeckListScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              title: 'Duel Simulator',
              icon: Icons.videogame_asset,
              color: Colors.redAccent,
              gradient: const LinearGradient(
                colors: [Colors.redAccent, Colors.deepOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DuelSimulatorScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              title: 'Match History',
              icon: Icons.history,
              color: Colors.orange,
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.amber],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MatchHistoryScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi Logout yang PASTI kembali ke LoginScreen
  void _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await authProvider.signOut();
      if (!context.mounted) return;

      Navigator.pop(context); // Tutup loading

      // Pastikan pindah ke LoginScreen & bersihkan stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false, // Hapus semua route sebelumnya
      );
    } catch (e) {
      Navigator.pop(context); // Tutup loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  // Widget kartu menu dengan gradient cantik
  Widget _buildMenuCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required Gradient gradient,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: gradient,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 70, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}