import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/scraper_game_hub.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SatisfyingScraperApp());
}

class SatisfyingScraperApp extends StatelessWidget {
  const SatisfyingScraperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Satisfying Scraper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF101014),
      ),
      home: const ScraperGameHub(),
    );
  }
}
