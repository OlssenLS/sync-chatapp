import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/websocket_service.dart';
import 'chat_detail_screen.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  } catch (e) {
    print("Firebase initialization error: $e");
  }

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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final WebSocketService _wsService = WebSocketService();

  @override
  void initState() {
    super.initState();
    themeController.addListener(_onThemeChanged);
    _setupNotificationHandling();
  }

  void _setupNotificationHandling() {
    NotificationService.onNotificationClick.listen((data) async {
      if (data['type'] == 'chat' && data['sender_id'] != null) {
        // Handle deep link to chat detail
        _navigateToChatDetail(data['sender_id']);
      }
    });
  }

  Future<void> _navigateToChatDetail(String senderId) async {
    // Ensure we are logged in
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) return;

    final myId = await AuthService.getUserId() ?? "";
    if (myId.isEmpty) return;

    // Connect WS if not connected
    _wsService.connect(myId);

    // Navigate using the navigator key to ensure we have context
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          userName: "Chat", // We could fetch the username here if needed
          userId: senderId,
          myId: myId,
          wsService: _wsService,
        ),
      ),
    );
  }

  @override
  void dispose() {
    themeController.removeListener(_onThemeChanged);
    _wsService.disconnect();
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
      navigatorKey: _navigatorKey,
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
