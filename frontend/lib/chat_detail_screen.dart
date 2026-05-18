import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/websocket_service.dart';
import 'services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String userName;
  final String userId;
  final String myId;
  final WebSocketService wsService;

  const ChatDetailScreen({
    super.key,
    required this.userName,
    required this.userId,
    required this.myId,
    required this.wsService,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<ChatMessage> _messages = [];
  StreamSubscription? _wsSubscription;

  void _loadHistory() async {
    log("Loading history for receiver: ${widget.userId}");
    if (widget.userId.isEmpty) {
       log("Error: receiver_id is empty!");
       return;
    }

    final history = await ChatService.getChatHistory(widget.myId, widget.userId);
    if (mounted) {
      _messages.clear();
      for (var msg in history) {
        final content = msg['content']?.toString() ?? "";
        if (content.isNotEmpty) {
          _messages.add(ChatMessage(
            content: content,
            isMe: msg['sender_id'] == widget.myId,
            time: _formatTimestamp(msg['timestamp']),
          ));
        }
      }

      setState(() {});

      // Instant jump to bottom to eliminate the "waiting for scroll" delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "12:00 PM";
    try {
      final dt = DateTime.parse(timestamp.toString()).toLocal();
      return "${dt.hour % 12 == 0 ? 12 : dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";
    } catch (e) {
      return "12:00 PM";
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    
    _wsSubscription = widget.wsService.messages.listen((data) {
      if (data['type'] == 'chat' && 
          (data['sender_id'] == widget.userId || data['sender_id'] == widget.myId)) {
        
        final content = data['content']?.toString() ?? "";
        if (content.isEmpty) return;

        final isMe = data['sender_id'] == widget.myId;
        final newMessage = ChatMessage(
          content: content,
          isMe: isMe,
          time: TimeOfDay.now().format(context),
        );

        if (mounted) {
          final insertIndex = _messages.length;
          setState(() {
            _messages.add(newMessage);
          });
          _listKey.currentState?.insertItem(insertIndex, duration: 400.ms);
          
          Future.delayed(100.ms, _scrollToBottom);
        }
      }
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: 400.ms,
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    widget.wsService.sendMessage(widget.userId, text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final String displayTitle = widget.userName.trim().isNotEmpty ? widget.userName : "User";
    final String initial = displayTitle[0].toUpperCase();

    return AppBar(
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          _buildExpressiveAvatar(initial),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayTitle,
                style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green, 
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                   .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1.seconds, curve: Curves.easeInOut),
                  const SizedBox(width: 6),
                  Text(
                    "Online",
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.videocam_rounded), onPressed: () {}),
        IconButton(icon: const Icon(Icons.call_rounded), onPressed: () {}),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildExpressiveAvatar(String label) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12).copyWith(
          bottomRight: const Radius.circular(2),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.syne(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildAnimatedMessageBubble(ChatMessage message, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(message.isMe ? 0.2 : -0.2, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
      child: FadeTransition(
        opacity: animation,
        child: _buildMessageBubble(message),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: message.isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(message.isMe ? 24 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 24),
          ),
          boxShadow: [
            if (message.isMe)
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Column(
          crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: message.isMe ? colorScheme.onPrimary : colorScheme.onSurface,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message.time,
              style: TextStyle(
                color: message.isMe ? colorScheme.onPrimary.withValues(alpha: 0.7) : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildInputIconButton(Icons.add_rounded),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 5,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _sendMessage,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: const Radius.circular(4),
          ),
        ),
        child: Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 22),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds);
  }
}

class ChatMessage {
  final String content;
  final bool isMe;
  final String time;

  ChatMessage({required this.content, required this.isMe, required this.time});
}
