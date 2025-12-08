import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/supabase_service.dart';

class DuelProvider extends ChangeNotifier {
  int _player1LP = 8000;
  int _player2LP = 8000;
  String _player1Name = 'Player 1';
  String _player2Name = 'Player 2';

  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;

  List<MatchHistory> _matchHistory = [];
  String _errorMessage = '';

  int get player1LP => _player1LP;
  int get player2LP => _player2LP;
  String get player1Name => _player1Name;
  String get player2Name => _player2Name;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isTimerRunning => _isTimerRunning;
  List<MatchHistory> get matchHistory => _matchHistory;
  String get errorMessage => _errorMessage;

  String get timerDisplay {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void setPlayerNames(String p1, String p2) {
    _player1Name = p1;
    _player2Name = p2;
    notifyListeners();
  }

  void setInitialLP(int lp) {
    _player1LP = lp;
    _player2LP = lp;
    notifyListeners();
  }

  void updatePlayer1LP(int change) {
    _player1LP += change;
    if (_player1LP < 0) _player1LP = 0;
    notifyListeners();
  }

  void updatePlayer2LP(int change) {
    _player2LP += change;
    if (_player2LP < 0) _player2LP = 0;
    notifyListeners();
  }

  void resetDuel() {
    _player1LP = 8000;
    _player2LP = 8000;
    stopTimer();
    _elapsedSeconds = 0;
    notifyListeners();
  }

  void startTimer() {
    if (_isTimerRunning) return;

    _isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  void stopTimer() {
    _isTimerRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void resetTimer() {
    stopTimer();
    _elapsedSeconds = 0;
    notifyListeners();
  }

  int rollDice(int sides) {
    final random = Random();
    return random.nextInt(sides) + 1;
  }

  bool flipCoin() {
    final random = Random();
    return random.nextBool();
  }

  Future<void> saveMatch() async {
    try {
      String winner = 'Draw';
      if (_player1LP > _player2LP) {
        winner = _player1Name;
      } else if (_player2LP > _player1LP) {
        winner = _player2Name;
      }

      final match = MatchHistory(
        player1Name: _player1Name,
        player2Name: _player2Name,
        player1LP: _player1LP,
        player2LP: _player2LP,
        winner: winner,
        matchDate: DateTime.now(),
        durationMinutes: _elapsedSeconds ~/ 60,
      );

      await SupabaseService.instance.addMatchHistory(match);
      await loadMatchHistory();
    } catch (e) {
      _errorMessage = 'Failed to save match: $e';
    }
  }

  Future<void> loadMatchHistory() async {
    try {
      _matchHistory = await SupabaseService.instance.getMatchHistory();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load match history: $e';
    }
  }

  Future<void> deleteMatch(dynamic id) async {
    try {
      await SupabaseService.instance.deleteMatchHistory(id);
      await loadMatchHistory();
    } catch (e) {
      _errorMessage = 'Failed to delete match: $e';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}