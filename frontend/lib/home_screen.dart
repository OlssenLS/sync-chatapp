import 'dart:async';
import 'services/chat_service.dart';
import 'services/websocket_service.dart';
import 'services/auth_service.dart';
import 'chat_detail_screen.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _tabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription? _wsSubscription;
  
  String _myId = ""; 
  List<dynamic> _conversations = [];
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeUser() async {
    final id = await AuthService.getUserId();
    if (id != null) {
      setState(() {
        _myId = id;
      });
      _wsService.connect(id);
      _fetchConversations();

      // Listen for WebSocket messages to update the chat list in real-time
      _wsSubscription = _wsService.messages.listen((data) {
        if (data['type'] == 'chat') {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
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
            ),
            _buildFloatingNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "SYNC",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Color(0xFF24A1DE),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await AuthService.logout();
                  if (mounted) Navigator.pushReplacementNamed(context, '/login');
                },
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFF0F2F5),
                  child: Icon(Icons.logout, color: Colors.black54, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(40),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search messages or users...",
                hintStyle: TextStyle(color: Colors.black38),
                prefixIcon: Icon(Icons.search, color: Colors.black38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(40),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double tabWidth = (constraints.maxWidth) / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: _tabIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _tabItem("All Chats", Icons.forum_outlined, 0),
                  _tabItem("Important", Icons.folder_outlined, 1),
                ],
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _tabItem(String title, IconData icon, int index) {
    bool isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF24A1DE) : Colors.black45,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.black45,
                ),
              ),
            ],
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
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text(
              "No chats yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            const Text(
              "Search users to start messaging!",
              style: TextStyle(color: Colors.black38),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: _conversations.length,
      separatorBuilder: (context, index) => const Divider(
        indent: 85,
        height: 1,
        color: Color(0xFFF0F2F5),
      ),
      itemBuilder: (context, index) {
        final conv = _conversations[index];
        final username = conv['other_username']?.toString() ?? "Unknown";
        final firstLetter = username.isNotEmpty ? username[0].toUpperCase() : "?";

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF24A1DE).withValues(alpha: 0.1),
            child: Text(firstLetter, style: const TextStyle(color: Color(0xFF24A1DE))),
          ),
          title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(conv['last_message']?.toString() ?? "", maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(_formatTime(conv['timestamp'])),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  userName: username,
                  userId: conv['other_user_id'],
                  myId: _myId,
                  wsService: _wsService,
                ),
              ),
            ).then((_) => _fetchConversations());
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text("No users found"));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(
        indent: 85,
        height: 1,
        color: Color(0xFFF0F2F5),
      ),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        if (user['id'] == _myId) return const SizedBox.shrink();

        final username = user['username']?.toString() ?? "Unknown";
        final firstLetter = username.isNotEmpty ? username[0].toUpperCase() : "?";

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF24A1DE).withValues(alpha: 0.1),
            child: Text(firstLetter, style: const TextStyle(color: Color(0xFF24A1DE))),
          ),
          title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(user['email']?.toString() ?? "", style: const TextStyle(color: Colors.black45)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  userName: username,
                  userId: user['id'],
                  myId: _myId,
                  wsService: _wsService,
                ),
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

  Widget _buildFloatingNavBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: IntrinsicWidth(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _navItem(Icons.chat_bubble_outline, Icons.chat_bubble, "Chats", 0),
                    _navItem(Icons.people_outline, Icons.people, "Contacts", 1),
                    _navItem(Icons.settings_outlined, Icons.settings, "Settings", 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData inactiveIcon, IconData activeIcon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF24A1DE).withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? const Color(0xFF24A1DE) : Colors.black38,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF24A1DE) : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
