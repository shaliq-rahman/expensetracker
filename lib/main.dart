import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/recurring_payment_provider.dart';
import 'package:expense_tracker/providers/pending_settlement_provider.dart';
import 'package:expense_tracker/screens/home_screen.dart';
import 'package:expense_tracker/screens/analytics_screen.dart';
import 'package:expense_tracker/screens/add_transaction_screen.dart';
import 'package:expense_tracker/widgets/custom_bottom_bar.dart';
import 'package:expense_tracker/screens/all_transactions_screen.dart';
import 'package:expense_tracker/screens/splash_screen.dart';
import 'package:expense_tracker/screens/login_screen.dart';

import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:expense_tracker/widgets/gradient_background.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/firebase_options.dart';
import 'package:expense_tracker/services/fcm_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initialize FCM
    await FCMService().initialise();
  } catch (e) {
    print("Firebase initialization failed: $e");
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RecurringPaymentProvider()),
        ChangeNotifierProvider(create: (_) => PendingSettlementProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Expense Tracker',
          debugShowCheckedModeBanner: false,
          
          // Force English Locale
          locale: const Locale('en'),
          supportedLocales: const [
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFC6F432), // Lime Green
              secondary: Color(0xFFC6F432),
              surface: Color(0xFFF5F5F5), // Light Grey Surface for Cards
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent, // Transparent for gradient
              elevation: 0,
              centerTitle: false,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardColor: const Color(0xFFF5F5F5), // Light Grey for Cards
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF050505), // Deep Black
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFC6F432), // Lime Green
              secondary: Color(0xFFC6F432),
              surface: Color(0xFF161618), // Dark Grey Surface
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent, // Transparent for gradient
              elevation: 0,
              centerTitle: false,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardColor: const Color(0xFF161618), // Dark Grey for Cards
          ),
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData) {
                return const SplashScreen();
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
