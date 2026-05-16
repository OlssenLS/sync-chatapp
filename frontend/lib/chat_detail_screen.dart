import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
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
      // CLEAR and RE-POPULATE properly for AnimatedList
      setState(() {
        _messages.clear();
      });

      for (int i = 0; i < history.length; i++) {
        final msg = history[i];
        final content = msg['content']?.toString() ?? "";
        if (content.isNotEmpty) {
          final newMessage = ChatMessage(
            content: content,
            isMe: msg['sender_id'] == widget.myId,
            time: _formatTimestamp(msg['timestamp']),
          );
          
          _messages.add(newMessage);
          _listKey.currentState?.insertItem(_messages.length - 1, duration: Duration.zero);
        }
      }

      // Delay auto-scroll to allow build to finish
      Future.delayed(const Duration(milliseconds: 500), _scrollToBottom);
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
    
    // Listen for real-time messages
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
          // Use a safer insertion pattern to avoid RangeError
          final insertIndex = _messages.length;
          setState(() {
            _messages.add(newMessage);
          });
          _listKey.currentState?.insertItem(insertIndex, duration: const Duration(milliseconds: 350));
          
          Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
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
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: AnimatedList(
              key: _listKey,
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              initialItemCount: _messages.length,
              itemBuilder: (context, index, animation) {
                // Safeguard against index out of bounds during list updates
                if (index >= _messages.length) return const SizedBox.shrink();
                return _buildAnimatedMessageBubble(_messages[index], animation);
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
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF24A1DE).withValues(alpha: 0.1),
            child: Text(
              initial,
              style: const TextStyle(color: Color(0xFF24A1DE), fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayTitle,
                style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Online",
                style: TextStyle(color: Color(0xFF24A1DE), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.more_vert, color: Colors.black54), onPressed: () {}),
      ],
    );
  }

  Widget _buildAnimatedMessageBubble(ChatMessage message, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
        child: _buildMessageBubble(message),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isMe ? const Color(0xFF24A1DE) : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isMe ? 20 : 0),
            bottomRight: Radius.circular(message.isMe ? 0 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: message.isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: TextStyle(
                color: message.isMe ? Colors.white70 : Colors.black38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F2F5), width: 1)),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF24A1DE), size: 26),
              onPressed: () {},
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 5,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    hintText: "Message",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.black38),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF24A1DE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String content;
  final bool isMe;
  final String time;

  ChatMessage({required this.content, required this.isMe, required this.time});
}
