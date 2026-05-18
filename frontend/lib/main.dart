import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Constants.init();
  final bool loggedIn = await AuthService.isLoggedIn();
  runApp(SyncChatApp(isLoggedIn: loggedIn));
}

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

final themeController = ThemeController();

class SyncChatApp extends StatefulWidget {
  final bool isLoggedIn;
  const SyncChatApp({super.key, required this.isLoggedIn});

  @override
  State<SyncChatApp> createState() => _SyncChatAppState();
}

class _SyncChatAppState extends State<SyncChatApp> {
  @override
  void initState() {
    super.initState();
    themeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Material Design Expressive Color Schemes
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF24A1DE),
      primary: const Color(0xFF24A1DE),
      secondary: const Color(0xFFFF6B6B),
      tertiary: const Color(0xFF4ECDC4),
      surfaceTint: Colors.white,
      brightness: Brightness.light,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF24A1DE),
      primary: const Color(0xFF34B3F1),
      secondary: const Color(0xFFFF8787),
      tertiary: const Color(0xFF72DED7),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'SYNC Chat',
      debugShowCheckedModeBanner: false,
      themeMode: themeController.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        textTheme: GoogleFonts.bricolageGrotesqueTextTheme().copyWith(
          displayLarge: GoogleFonts.syne(fontWeight: FontWeight.w800),
          displayMedium: GoogleFonts.syne(fontWeight: FontWeight.w800),
          displaySmall: GoogleFonts.syne(fontWeight: FontWeight.w800),
          headlineLarge: GoogleFonts.syne(fontWeight: FontWeight.w800),
          titleLarge: GoogleFonts.syne(fontWeight: FontWeight.w700),
        ).apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        textTheme: GoogleFonts.bricolageGrotesqueTextTheme().copyWith(
          displayLarge: GoogleFonts.syne(fontWeight: FontWeight.w800),
          displayMedium: GoogleFonts.syne(fontWeight: FontWeight.w800),
          displaySmall: GoogleFonts.syne(fontWeight: FontWeight.w800),
          headlineLarge: GoogleFonts.syne(fontWeight: FontWeight.w800),
          titleLarge: GoogleFonts.syne(fontWeight: FontWeight.w700),
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
      ),
      initialRoute: widget.isLoggedIn ? '/home' : '/onboarding',
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
