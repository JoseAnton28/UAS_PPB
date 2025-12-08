import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/card_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('yugioh_companion.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE decks (
        id $idType,
        name $textType,
        mainDeck $textType,
        extraDeck $textType,
        sideDeck $textType,
        createdAt $textType,
        updatedAt $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id $idType,
        cardId $intType,
        cardData $textType,
        addedAt $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE match_history (
        id $idType,
        player1Name $textType,
        player2Name $textType,
        player1LP $intType,
        player2LP $intType,
        winner $textType,
        matchDate $textType,
        durationMinutes $intType
      )
    ''');
  }

  // Deck operations
  Future<int> createDeck(Deck deck) async {
    final db = await database;
    return await db.insert('decks', {
      'name': deck.name,
      'mainDeck': json.encode(deck.mainDeck.map((c) => c.toJson()).toList()),
      'extraDeck': json.encode(deck.extraDeck.map((c) => c.toJson()).toList()),
      'sideDeck': json.encode(deck.sideDeck.map((c) => c.toJson()).toList()),
      'createdAt': deck.createdAt.toIso8601String(),
      'updatedAt': deck.updatedAt.toIso8601String(),
    });
  }

  Future<List<Deck>> getAllDecks() async {
    final db = await database;
    final result = await db.query('decks', orderBy: 'updatedAt DESC');

    return result.map((json) => Deck(
      id: json['id'] as int,
      name: json['name'] as String,
      mainDeck: (jsonDecode(json['mainDeck'] as String) as List)
          .map((c) => DeckCard(
        card: YugiohCard.fromJson(c['card']),
        quantity: c['quantity'],
      ))
          .toList(),
      extraDeck: (jsonDecode(json['extraDeck'] as String) as List)
          .map((c) => DeckCard(
        card: YugiohCard.fromJson(c['card']),
        quantity: c['quantity'],
      ))
          .toList(),
      sideDeck: (jsonDecode(json['sideDeck'] as String) as List)
          .map((c) => DeckCard(
        card: YugiohCard.fromJson(c['card']),
        quantity: c['quantity'],
      ))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    )).toList();
  }

  Future<int> updateDeck(Deck deck) async {
    final db = await database;
    return await db.update(
      'decks',
      {
        'name': deck.name,
        'mainDeck': json.encode(deck.mainDeck.map((c) => c.toJson()).toList()),
        'extraDeck': json.encode(deck.extraDeck.map((c) => c.toJson()).toList()),
        'sideDeck': json.encode(deck.sideDeck.map((c) => c.toJson()).toList()),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [deck.id],
    );
  }

  Future<int> deleteDeck(int id) async {
    final db = await database;
    return await db.delete('decks', where: 'id = ?', whereArgs: [id]);
  }

  // Favorites operations
  Future<int> addFavorite(YugiohCard card) async {
    final db = await database;
    return await db.insert('favorites', {
      'cardId': card.id,
      'cardData': json.encode(card.toJson()),
      'addedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<YugiohCard>> getFavorites() async {
    final db = await database;
    final result = await db.query('favorites', orderBy: 'addedAt DESC');

    return result.map((json) {
      final cardData = jsonDecode(json['cardData'] as String);
      return YugiohCard.fromJson(cardData);
    }).toList();
  }

  Future<int> removeFavorite(int cardId) async {
    final db = await database;
    return await db.delete('favorites', where: 'cardId = ?', whereArgs: [cardId]);
  }

  Future<bool> isFavorite(int cardId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'cardId = ?',
      whereArgs: [cardId],
    );
    return result.isNotEmpty;
  }

  // Match history operations
  Future<int> addMatchHistory(MatchHistory match) async {
    final db = await database;
    return await db.insert('match_history', match.toMap());
  }

  Future<List<MatchHistory>> getMatchHistory() async {
    final db = await database;
    final result = await db.query('match_history', orderBy: 'matchDate DESC');
    return result.map((map) => MatchHistory.fromMap(map)).toList();
  }

  Future<int> deleteMatchHistory(int id) async {
    final db = await database;
    return await db.delete('match_history', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}