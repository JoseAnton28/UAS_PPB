import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/card_model.dart';

class ApiService {
  static const String _baseUrl = 'https://db.ygoprodeck.com/api/v7';

  static Future<List<YugiohCard>> getAllCards() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/cardinfo.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;
        return data.map((json) => YugiohCard.fromJson(json)).toList();
      }
      throw Exception('Failed to load cards');
    } catch (e) {
      debugPrint('getAllCards error: $e');
      rethrow;
    }
  }

  static Future<List<YugiohCard>> searchCards(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final url = '$_baseUrl/cardinfo.php?fname=${Uri.encodeComponent(query)}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;
        return data.map((json) => YugiohCard.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('searchCards error: $e');
      return [];
    }
  }

  // BARU: Banlist TCG & OCG
  static Future<List<YugiohCard>> getBanlistCards(String format) async {
    if (!['tcg', 'ocg'].contains(format.toLowerCase())) {
      throw Exception('Format harus tcg atau ocg');
    }
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cardinfo.php?banlist=$format'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;
        return data.map((json) => YugiohCard.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('getBanlistCards error: $e');
      return [];
    }
  }
}