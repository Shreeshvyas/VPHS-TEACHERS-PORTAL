import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/portal_provider.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PortalProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teacher Portal',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Defaulting to deep premium dark theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFF0A0B10),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFFA855F7),
          surface: Color(0xFF12131A),
          error: Colors.redAccent,
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF12131A),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
