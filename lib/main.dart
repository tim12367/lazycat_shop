import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lazycat_shop/api_service.dart';
import 'package:lazycat_shop/config.dart';
import 'package:provider/provider.dart';

import 'home_page.dart';
import 'login_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Config>(create: (_) => Config()),
        Provider<ApiService>(create: (_) => ApiService(context)),
      ],
      child: MaterialApp(
        title: 'Lazycat Shop',

        // 導頁
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/login': (context) => const LoginPage(),
        },

        // 主題
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purple,
            brightness: Brightness.dark,
          ),
          textTheme: TextTheme(
            displayLarge: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
            ),
            titleLarge: GoogleFonts.oswald(
              fontSize: 30,
              fontStyle: FontStyle.normal,
            ),
            bodyMedium: GoogleFonts.merriweather(),
            displaySmall: GoogleFonts.pacifico(),
          ),
        ),
      ),
    );
  }
}
