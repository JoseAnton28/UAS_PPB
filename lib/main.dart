import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/card_provider.dart';
import 'providers/deck_provider.dart';
import 'providers/duel_provider.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

  // TEST: Check if user can save to database
  await _testDatabaseAccess();

  runApp(const MyApp());
}

Future<void> _testDatabaseAccess() async {
  try {
    print('🔍 Testing database access...');

    final session = SupabaseService.client.auth.currentSession;
    if (session != null) {
      print('✅ Session found!');
      print('📧 Email: ${session.user.email}');
      print('📝 User ID: ${session.user.id}');
      print('⏰ Expires at: ${session.expiresAt}');

      // Test query to decks table
      try {
        final response = await SupabaseService.client
            .from('decks')
            .select()
            .limit(1);

        print('✅ Database access OK! Found ${(response as List).length} decks');
      } catch (e) {
        print('❌ Database query error: $e');
      }
    } else {
      print('⚠️ No active session - User needs to login');
    }
  } catch (e) {
    print('❌ Database access error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CardProvider()),
        ChangeNotifierProvider(create: (_) => DeckProvider()),
        ChangeNotifierProvider(create: (_) => DuelProvider()),
      ],
      child: MaterialApp(
        title: 'Yu-Gi-Oh! Companion',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.purple,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1a1a2e),
          cardColor: const Color(0xFF16213e),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0f3460),
            elevation: 0,
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Show LoginScreen if not authenticated, HomeScreen if authenticated
            return authProvider.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen();
          },
        ),
      ),
    );
  }
}