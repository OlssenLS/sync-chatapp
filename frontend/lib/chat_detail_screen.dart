import 'package:flutter/material.dart';

class ChatDetailScreen extends StatefulWidget {
  final String userName;
  const ChatDetailScreen({super.key, required this.userName});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  
  final List<ChatMessage> _messages = [
    ChatMessage(content: "Hey there!", isMe: false, time: "10:00 AM"),
    ChatMessage(content: "How's the new SYNC app?", isMe: false, time: "10:01 AM"),
    ChatMessage(content: "It's looking amazing! Just added the glass effects.", isMe: true, time: "10:05 AM"),
  ];

  @override
  void dispose() {
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
    if (_messageController.text.trim().isEmpty) return;
    
    final newMessage = ChatMessage(
      content: _messageController.text.trim(),
      isMe: true,
      time: TimeOfDay.now().format(context),
    );

    setState(() {
      _messages.add(newMessage);
      _listKey.currentState?.insertItem(_messages.length - 1, duration: const Duration(milliseconds: 350));
      _messageController.clear();
    });

    // Auto-scroll after a short delay to allow the animation to start
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    // Simulate receiving a message
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final reply = ChatMessage(
          content: "That sounds awesome! 🚀",
          isMe: false,
          time: TimeOfDay.now().format(context),
        );
        setState(() {
          _messages.add(reply);
          _listKey.currentState?.insertItem(_messages.length - 1, duration: const Duration(milliseconds: 350));
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });
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
              widget.userName[0],
              style: const TextStyle(color: Color(0xFF24A1DE), fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userName,
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
          crossAxisAlignment: CrossAxisAlignment.center, // Vertically center all items
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF24A1DE), size: 26),
              onPressed: () {},
              constraints: const BoxConstraints(), // Remove default button constraints
              padding: const EdgeInsets.all(8),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 5,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textAlignVertical: TextAlignVertical.center, // Ensure text is centered
                  decoration: const InputDecoration(
                    hintText: "Message",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.black38),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8), // Adjust inner padding
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
                child: const Icon(Icons.send, color: Colors.white, size: 18),
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
