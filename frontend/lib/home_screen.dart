import 'dart:async';
import 'services/chat_service.dart';
import 'services/websocket_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'chat_detail_screen.dart';
import 'main.dart'; // To access themeController
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _tabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription? _wsSubscription;
  
  String _myId = ""; 
  String _myUsername = "";
  String _myEmail = ""; // We might need to store email in prefs or fetch it
  List<dynamic> _conversations = [];
  List<dynamic> _allUsers = [];
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = true;
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeUser() async {
    final id = await AuthService.getUserId();
    final username = await AuthService.getUsername();
    // For email, we might want to update AuthService to store it, but for now let's assume we can get it or just show username
    
    if (id != null) {
      setState(() {
        _myId = id;
        _myUsername = username ?? "User";
      });
      _wsService.connect(id);
      NotificationService.registerToken(id);
      _fetchConversations();
      _fetchAllUsers();

      _wsSubscription = _wsService.messages.listen((data) {
        if (data['type'] == 'chat' || data['type'] == 'read') {
          _fetchConversations();
        }
      });
    }
  }

  void _fetchConversations() async {
    if (_myId.isEmpty) return;
    final conversations = await ChatService.getActiveConversations(_myId);
    if (mounted) {
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    }
  }

  void _fetchAllUsers() async {
    final users = await ChatService.getAllUsers();
    if (mounted) {
      setState(() {
        _allUsers = users;
        _isLoadingUsers = false;
      });
    }
  }

  void _onSearchChanged() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await ChatService.searchUsers(_searchController.text);
    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _wsService.disconnect();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: [
                _buildChatsPage(),
                _buildContactsPage(),
                _buildSettingsPage(),
              ],
            ),
            _buildDockedToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsPage() {
    return Column(
      children: [
        _buildHeader("SYNC"),
        const SizedBox(height: 20),
        _buildTabSection(),
        const SizedBox(height: 10),
        Expanded(
          child: _isSearching 
            ? _buildSearchResults() 
            : _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _buildChatList(),
        ),
      ],
    );
  }

  Widget _buildContactsPage() {
    return Column(
      children: [
        _buildHeader("Contacts"),
        const SizedBox(height: 20),
        Expanded(
          child: _isLoadingUsers 
            ? const Center(child: CircularProgressIndicator())
            : _buildAllUsersList(),
        ),
      ],
    );
  }

  Widget _buildSettingsPage() {
    return Column(
      children: [
        _buildHeader("Settings"),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileCard(),
                const SizedBox(height: 32),
                _buildSettingsSection("Preferences", [
                  _settingsItem(
                    Icons.palette_rounded, 
                    "Appearance", 
                    "Change app theme",
                    trailing: _buildThemeToggleSmall(),
                  ),
                  _settingsItem(
                    Icons.notifications_active_rounded, 
                    "Notifications", 
                    "Manage your alerts",
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSettingsSection("Account", [
                  _settingsItem(
                    Icons.lock_rounded, 
                    "Privacy & Security", 
                    "Encryption, block list",
                  ),
                  _settingsItem(
                    Icons.help_outline_rounded, 
                    "Help & Feedback", 
                    "Support center",
                  ),
                ]),
                const SizedBox(height: 40),
                _buildLogoutButton(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildExpressiveAvatar(_myUsername.isNotEmpty ? _myUsername[0].toUpperCase() : "?", Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            _myUsername,
            style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          Text(
            "Available",
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 100.ms);
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.syne(
              fontSize: 16, 
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _settingsItem(IconData icon, String title, String subtitle, {Widget? trailing}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: () {},
    );
  }

  Widget _buildThemeToggleSmall() {
    bool isDark = themeController.themeMode == ThemeMode.dark;
    return Switch(
      value: isDark,
      onChanged: (_) => themeController.toggleTheme(),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          await AuthService.logout();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        label: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  Widget _buildAllUsersList() {
    final otherUsers = _allUsers.where((u) => u['id'] != _myId).toList();

    if (otherUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 80, color: Theme.of(context).colorScheme.primaryContainer),
            const SizedBox(height: 24),
            Text(
              "No users found",
              style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120, top: 10),
      itemCount: otherUsers.length,
      itemBuilder: (context, index) {
        final user = otherUsers[index];
        final username = user['username']?.toString() ?? "Unknown";
        final firstLetter = username.isNotEmpty ? username[0].toUpperCase() : "?";

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leading: _buildExpressiveAvatar(firstLetter, Theme.of(context).colorScheme.secondary),
          title: Text(
            username, 
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          subtitle: Text(user['email']?.toString() ?? ""),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: 400.ms,
                reverseTransitionDuration: 300.ms,
                pageBuilder: (context, animation, secondaryAnimation) => ChatDetailScreen(
                  userName: username,
                  userId: user['id'],
                  myId: _myId,
                  wsService: _wsService,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  final slideAnimation = Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ));

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slideAnimation,
                      child: child,
                    ),
                  );
                },
              ),
            ).then((_) => _fetchConversations());
          },
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.syne(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: title == "SYNC" ? 2 : 0,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ).animate(key: ValueKey(title)).fadeIn().slideX(begin: -0.2),
              if (title == "SYNC")
                Row(
                  children: [
                    _buildThemeToggle(),
                    const SizedBox(width: 8),
                    _buildProfileButton(),
                  ],
                ),
            ],
          ),
          if (title == "SYNC") ...[
            const SizedBox(height: 24),
            _buildSearchBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeToggle() {
    bool isDark = themeController.themeMode == ThemeMode.dark;
    return IconButton(
      onPressed: () => themeController.toggleTheme(),
      icon: AnimatedSwitcher(
        duration: 300.ms,
        transitionBuilder: (child, anim) => RotationTransition(
          turns: anim,
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(isDark),
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildProfileButton() {
    return GestureDetector(
      onTap: () async {
        await AuthService.logout();
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: const Radius.circular(4),
          ),
        ),
        child: Icon(
          Icons.logout_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search messages or users...",
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _tabItem("All Chats", Icons.forum_rounded, 0),
          _tabItem("Important", Icons.star_rounded, 1),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _tabItem(String title, IconData icon, int index) {
    bool isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedScale(
          scale: isSelected ? 1.05 : 1.0,
          duration: 400.ms,
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: 300.ms,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ] : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.syne(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Theme.of(context).colorScheme.primaryContainer),
            const SizedBox(height: 24),
            Text(
              "No chats yet",
              style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text("Search users to start messaging!"),
          ],
        ).animate().fadeIn().scale(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120, top: 10),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conv = _conversations[index];
        return _buildChatTile(conv).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildChatTile(dynamic conv) {
    final username = conv['other_username']?.toString() ?? "Unknown";
    final firstLetter = username.isNotEmpty ? username[0].toUpperCase() : "?";
    final userId = conv['other_user_id'];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: _buildExpressiveAvatar(firstLetter, Theme.of(context).colorScheme.primary),
      title: Text(
        username,
        style: GoogleFonts.bricolageGrotesque(
          fontWeight: FontWeight.w700, 
          fontSize: 18,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        conv['last_message']?.toString() ?? "",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: 14,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(conv['timestamp']),
            style: TextStyle(
              fontSize: 12, 
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (conv['unread_count'] != null && conv['unread_count'] > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary, 
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                conv['unread_count'].toString(),
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.seconds),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: 400.ms,
            reverseTransitionDuration: 300.ms,
            pageBuilder: (context, animation, secondaryAnimation) => ChatDetailScreen(
              userName: username,
              userId: userId,
              myId: _myId,
              wsService: _wsService,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final slideAnimation = Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ));

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: child,
                ),
              );
            },
          ),
        ).then((_) => _fetchConversations());
      },
    );
  }

  Widget _buildExpressiveAvatar(String label, Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18).copyWith(
          topLeft: const Radius.circular(28),
          bottomRight: const Radius.circular(28),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.syne(color: color, fontWeight: FontWeight.w800, fontSize: 20),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text("No users found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120, top: 10),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        if (user['id'] == _myId) return const SizedBox.shrink();

        final username = user['username']?.toString() ?? "Unknown";
        final firstLetter = username.isNotEmpty ? username[0].toUpperCase() : "?";

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leading: _buildExpressiveAvatar(firstLetter, Theme.of(context).colorScheme.secondary),
          title: Text(
            username, 
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          subtitle: Text(user['email']?.toString() ?? ""),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: 400.ms,
                reverseTransitionDuration: 300.ms,
                pageBuilder: (context, animation, secondaryAnimation) => ChatDetailScreen(
                  userName: username,
                  userId: user['id'],
                  myId: _myId,
                  wsService: _wsService,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  final slideAnimation = Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ));

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slideAnimation,
                      child: child,
                    ),
                  );
                },
              ),
            ).then((_) {
               _searchController.clear();
               _fetchConversations();
            });
          },
        );
      },
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "";
    try {
      final dt = DateTime.parse(timestamp.toString()).toLocal();
      return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "";
    }
  }

  Widget _buildDockedToolbar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navItem(Icons.chat_bubble_rounded, 0),
              _navItem(Icons.people_alt_rounded, 1),
              _navItem(Icons.settings_rounded, 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: 500.ms,
          curve: Curves.easeOutQuart,
        );
      },
      child: AnimatedContainer(
        duration: 400.ms,
        curve: Curves.easeOutBack,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 24 : 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          icon,
          color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }
}
