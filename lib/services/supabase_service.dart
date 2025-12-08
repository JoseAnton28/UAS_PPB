import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_model.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  SupabaseService._init();

  static SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://yyhzcartqpczjfcfxauj.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl5aHpjYXJ0cXBjempmY2Z4YXVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxMDY3NTQsImV4cCI6MjA4MDY4Mjc1NH0.Tt38qzc-qSUPKhf_kq5sWrM8SbdLnRdq-VvvPbsT9O0',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );

    print('🔐 Supabase initialized');
    final session = client.auth.currentSession;
    if (session != null) {
      print('✅ Session found: ${session.user.email}');
    } else {
      print('⚠️ No active session');
    }
  }

  // ========== DECK OPERATIONS ==========

  Future<String> createDeck(Deck deck) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in. Please login first.');
      }

      print('📤 Sending deck data to Supabase...');
      print('User ID: $userId');
      print('Deck name: ${deck.name}');

      final response = await client.from('decks').insert({
        'user_id': userId,
        'name': deck.name,
        'main_deck': deck.mainDeck.map((c) => c.toJson()).toList(),
        'extra_deck': deck.extraDeck.map((c) => c.toJson()).toList(),
        'side_deck': deck.sideDeck.map((c) => c.toJson()).toList(),
      }).select('id').single();

      print('✅ Response received: $response');

      return response['id'] as String;
    } catch (e) {
      print('❌ Error creating deck: $e');
      throw Exception('Failed to create deck: $e');
    }
  }

  Future<List<Deck>> getAllDecks() async {
    try {
      print('📥 Fetching decks from Supabase...');

      final response = await client
          .from('decks')
          .select()
          .order('updated_at', ascending: false);

      print('✅ Fetched ${(response as List).length} decks');

      return (response).map((json) {
        return Deck(
          id: json['id'],
          name: json['name'],
          mainDeck: (json['main_deck'] as List)
              .map((c) => DeckCard(
            card: YugiohCard.fromJson(c['card']),
            quantity: c['quantity'],
          ))
              .toList(),
          extraDeck: (json['extra_deck'] as List)
              .map((c) => DeckCard(
            card: YugiohCard.fromJson(c['card']),
            quantity: c['quantity'],
          ))
              .toList(),
          sideDeck: (json['side_deck'] as List)
              .map((c) => DeckCard(
            card: YugiohCard.fromJson(c['card']),
            quantity: c['quantity'],
          ))
              .toList(),
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['updated_at']),
        );
      }).toList();
    } catch (e) {
      print('❌ Error fetching decks: $e');
      throw Exception('Failed to load decks: $e');
    }
  }

  Future<void> updateDeck(Deck deck) async {
    try {
      print('🔄 Updating deck: ${deck.name}');

      await client.from('decks').update({
        'name': deck.name,
        'main_deck': deck.mainDeck.map((c) => c.toJson()).toList(),
        'extra_deck': deck.extraDeck.map((c) => c.toJson()).toList(),
        'side_deck': deck.sideDeck.map((c) => c.toJson()).toList(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', deck.id);

      print('✅ Deck updated successfully');
    } catch (e) {
      print('❌ Error updating deck: $e');
      throw Exception('Failed to update deck: $e');
    }
  }

  Future<void> deleteDeck(dynamic id) async {
    await client.from('decks').delete().eq('id', id);
  }

  // ========== FAVORITES OPERATIONS ==========

  Future<void> addFavorite(YugiohCard card) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await client.from('favorites').upsert({
      'user_id': userId,
      'card_id': card.id,
      'card_data': card.toJson(),
    });
  }

  Future<List<YugiohCard>> getFavorites() async {
    final response = await client
        .from('favorites')
        .select()
        .order('added_at', ascending: false);

    return (response as List).map((json) {
      return YugiohCard.fromJson(json['card_data']);
    }).toList();
  }

  Future<void> removeFavorite(int cardId) async {
    await client.from('favorites').delete().eq('card_id', cardId);
  }

  Future<bool> isFavorite(int cardId) async {
    final response = await client
        .from('favorites')
        .select()
        .eq('card_id', cardId)
        .maybeSingle();

    return response != null;
  }

  // ========== MATCH HISTORY OPERATIONS ==========

  Future<String> addMatchHistory(MatchHistory match) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await client.from('match_history').insert({
      'user_id': userId,
      'player1_name': match.player1Name,
      'player2_name': match.player2Name,
      'player1_lp': match.player1LP,
      'player2_lp': match.player2LP,
      'winner': match.winner,
      'duration_minutes': match.durationMinutes,
    }).select('id').single();

    return response['id'] as String;
  }

  Future<List<MatchHistory>> getMatchHistory() async {
    final response = await client
        .from('match_history')
        .select()
        .order('match_date', ascending: false);

    return (response as List).map((json) {
      return MatchHistory(
        id: json['id'],
        player1Name: json['player1_name'],
        player2Name: json['player2_name'],
        player1LP: json['player1_lp'],
        player2LP: json['player2_lp'],
        winner: json['winner'],
        matchDate: DateTime.parse(json['match_date']),
        durationMinutes: json['duration_minutes'],
      );
    }).toList();
  }

  Future<void> deleteMatchHistory(dynamic id) async {
    await client.from('match_history').delete().eq('id', id);
  }

  // ========== USER PROFILE OPERATIONS ==========

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    return await getUserProfile(userId);
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (bio != null) updates['bio'] = bio;

    await client.from('user_profiles').update(updates).eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    final response = await client
        .from('leaderboard')
        .select()
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }
}