import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/duel_provider.dart';

class DuelSimulatorScreen extends StatelessWidget {
  const DuelSimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duel Simulator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: Consumer<DuelProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
                            Expanded(
                child: _buildPlayerSection(
                  context,
                  provider.player2Name,
                  provider.player2LP,
                  isPlayer1: false,
                  onUpdate: provider.updatePlayer2LP,
                ),
              ),

                            Container(
                color: const Color(0xFF0f3460),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                                        Text(
                      provider.timerDisplay,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            provider.isTimerRunning ? Icons.pause : Icons.play_arrow,
                          ),
                          onPressed: () {
                            if (provider.isTimerRunning) {
                              provider.stopTimer();
                            } else {
                              provider.startTimer();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: provider.resetTimer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                                        Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildToolButton(
                          context,
                          Icons.casino,
                          'Roll Dice',
                              () => _showDiceDialog(context, provider),
                        ),
                        _buildToolButton(
                          context,
                          Icons.monetization_on,
                          'Flip Coin',
                              () => _showCoinDialog(context, provider),
                        ),
                        _buildToolButton(
                          context,
                          Icons.refresh,
                          'Reset',
                              () => _showResetDialog(context, provider),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _saveMatch(context, provider),
                      icon: const Icon(Icons.save),
                      label: const Text('Save Match'),
                    ),
                  ],
                ),
              ),

                            Expanded(
                child: _buildPlayerSection(
                  context,
                  provider.player1Name,
                  provider.player1LP,
                  isPlayer1: true,
                  onUpdate: provider.updatePlayer1LP,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerSection(
      BuildContext context,
      String name,
      int lp,
      {required bool isPlayer1,
        required Function(int) onUpdate}
      ) {
    return Container(
      color: isPlayer1 ? const Color(0xFF1a1a2e) : const Color(0xFF16213e),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lp.toString(),
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: lp > 4000 ? Colors.green : lp > 2000 ? Colors.orange : Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLPButton('+100', () => onUpdate(100)),
              _buildLPButton('+500', () => onUpdate(500)),
              _buildLPButton('+1000', () => onUpdate(1000)),
              _buildLPButton('-100', () => onUpdate(-100)),
              _buildLPButton('-500', () => onUpdate(-500)),
              _buildLPButton('-1000', () => onUpdate(-1000)),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showCustomLPDialog(context, onUpdate),
            child: const Text('Custom Amount'),
          ),
        ],
      ),
    );
  }

  Widget _buildLPButton(String label, VoidCallback onPressed) {
    final isPositive = label.startsWith('+');
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPositive ? Colors.green : Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildToolButton(
      BuildContext context,
      IconData icon,
      String label,
      VoidCallback onPressed,
      ) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 32),
          onPressed: onPressed,
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showCustomLPDialog(BuildContext context, Function(int) onUpdate) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom LP Change'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter amount (use - for negative)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) {
                onUpdate(value);
                Navigator.pop(context);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showDiceDialog(BuildContext context, DuelProvider provider) {
    int result = 0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Roll Dice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result > 0)
                Text(
                  result.toString(),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => result = provider.rollDice(6)),
                    child: const Text('1d6'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final r1 = provider.rollDice(6);
                      final r2 = provider.rollDice(6);
                      setState(() => result = r1 + r2);
                    },
                    child: const Text('2d6'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCoinDialog(BuildContext context, DuelProvider provider) {
    String result = '';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Flip Coin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result.isNotEmpty)
                Text(
                  result,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final isHeads = provider.flipCoin();
                  setState(() => result = isHeads ? 'Heads' : 'Tails');
                },
                child: const Text('Flip'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final p1Controller = TextEditingController(
      text: context.read<DuelProvider>().player1Name,
    );
    final p2Controller = TextEditingController(
      text: context.read<DuelProvider>().player2Name,
    );
    int selectedLP = 8000;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Duel Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: p1Controller,
                decoration: const InputDecoration(labelText: 'Player 1 Name'),
              ),
              TextField(
                controller: p2Controller,
                decoration: const InputDecoration(labelText: 'Player 2 Name'),
              ),
              const SizedBox(height: 16),
              const Text('Starting LP:'),
              DropdownButton<int>(
                value: selectedLP,
                items: [4000, 8000, 16000].map((lp) {
                  return DropdownMenuItem(value: lp, child: Text('$lp LP'));
                }).toList(),
                onChanged: (value) => setState(() => selectedLP = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final provider = context.read<DuelProvider>();
                provider.setPlayerNames(p1Controller.text, p2Controller.text);
                provider.setInitialLP(selectedLP);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, DuelProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Duel'),
        content: const Text('Are you sure you want to reset the duel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.resetDuel();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _saveMatch(BuildContext context, DuelProvider provider) async {
    await provider.saveMatch();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match saved successfully!')),
      );
    }
  }
}