import 'dart:convert';
import 'package:flutter/foundation.dart'; // INI YANG WAJIB DITAMBAHKAN!
import 'package:http/http.dart' as http;
import '../models/card_model.dart';

class ApiService {
  // API resmi YGOPRODeck – cepat, gratis, selalu update
  static const String _baseUrl = 'https://db.ygoprodeck.com/api/v7';

  /// Load SEMUA kartu (13.000+ kartu) – dipanggil sekali saat pertama buka database
  static Future<List<YugiohCard>> getAllCards() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/cardinfo.php'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> cardList = jsonData['data'];
        return cardList.map((json) => YugiohCard.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load cards: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService.getAllCards() error: $e'); // Sekarang bisa!
      rethrow;
    }
  }

  /// Search kartu berdasarkan nama (lebih akurat & cepat dari filter lokal)
  static Future<List<YugiohCard>> searchCards(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final encodedQuery = Uri.encodeComponent(query.trim());
      final response = await http
          .get(Uri.parse('$_baseUrl/cardinfo.php?fname=$encodedQuery'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> cardList = jsonData['data'];
        return cardList.map((json) => YugiohCard.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('ApiService.searchCards() error: $e'); // Sekarang bisa!
      return [];
    }
  }
}