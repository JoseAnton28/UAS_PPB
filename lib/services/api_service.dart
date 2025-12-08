import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/card_model.dart';

class ApiService {
  static const String baseUrl = 'https://db.ygoprodeck.com/api/v7';

  static Future<List<YugiohCard>> getAllCards() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cardinfo.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> cardsJson = data['data'];
        return cardsJson.map((json) => YugiohCard.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load cards');
      }
    } catch (e) {
      throw Exception('Error fetching cards: $e');
    }
  }

  static Future<List<YugiohCard>> searchCards(String query) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/cardinfo.php?fname=$query')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> cardsJson = data['data'];
        return cardsJson.map((json) => YugiohCard.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<YugiohCard?> getCardById(int id) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/cardinfo.php?id=$id')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> cardsJson = data['data'];
        if (cardsJson.isNotEmpty) {
          return YugiohCard.fromJson(cardsJson[0]);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<YugiohCard>> filterCards({
    String? type,
    String? race,
    String? attribute,
    int? level,
  }) async {
    try {
      var url = '$baseUrl/cardinfo.php?';

      if (type != null) url += 'type=$type&';
      if (race != null) url += 'race=$race&';
      if (attribute != null) url += 'attribute=$attribute&';
      if (level != null) url += 'level=$level&';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> cardsJson = data['data'];
        return cardsJson.map((json) => YugiohCard.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}