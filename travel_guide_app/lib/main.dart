import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; 
import 'screens/login_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/visited_attractions.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light();
    return MaterialApp(
      title: 'Turkish Attractions',
      theme: baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: Colors.teal,
          secondary: Colors.tealAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.teal),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(), 
        '/admin': (context) => AdminScreen(),
        '/visited_attractions': (context) => const VisitedAttractionsScreen(),
      },
    );
  }
}
