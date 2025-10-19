import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/rive_animation_screen.dart'; // 👈 import your Rive screen here
import 'screens/chat_list_screen.dart'; // 👈 your main chat/home screen
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.registerAdaptersAndOpenBoxes();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final pinkPrimary = Colors.pinkAccent.shade200;

    return MaterialApp(
      title: 'LLM Chat',
      debugShowCheckedModeBanner: false,

      // 🌈 Define your theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: pinkPrimary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.pink.shade50,
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: pinkPrimary,
          foregroundColor: Colors.white,
          elevation: 3,
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: pinkPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: Colors.pink.shade200),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: pinkPrimary, width: 2),
          ),
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: pinkPrimary,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),

      themeMode: ThemeMode.system,

      // 🏁 Entry point
      home: const SplashScreen(),

      // 🌍 Routes section — add all screens here
      routes: {
        '/rive': (context) => const RiveAnimationScreen(),
        '/home': (context) => const ChatListScreen(),
      },
    );
  }
}
