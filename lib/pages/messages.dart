import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String currentUserId;
  final String receiverProfile;

  const MessagesPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.currentUserId,
    required this.receiverProfile,
  });

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _primaryFontFamily = 'PlusJakartaSans';
  static const TextStyle _appBarTitleStyle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );
  static const TextStyle _messageTextStyle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 15,
    height: 1.4,
  );
  static const TextStyle _inputHintStyle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 15,
    color: Colors.grey,
  );

  String getChatRoomId(String userA, String userB) {
    return userA.compareTo(userB) <= 0 ? '$userA\_$userB' : '$userB\_$userA';
  }

  void sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final chatRoomId = getChatRoomId(widget.currentUserId, widget.receiverId);

    // 1️⃣ Add message to messages collection
    await _firestore.collection("messages").add({
      "senderID": widget.currentUserId,
      "receiverID": widget.receiverId,
      "message": text,
      "timestamp": FieldValue.serverTimestamp(),
      "chatRoomID": chatRoomId,
      "read": "false",
    });

    // 2️⃣ Add notification for receiver
    await _firestore.collection("notifications").add({
      "userId": widget.receiverId,                  // the recipient
      "title": "New Message",                       // notification title
      "message": text,                              // message content
      "isRead": false,                              // mark as unread
      "timestamp": FieldValue.serverTimestamp(),    // server timestamp
    });

    // 3️⃣ Scroll to top
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myColor = isDark ? Colors.green.shade700 : const Color(0xFF4CAF50);
    final otherColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    final chatRoomId = getChatRoomId(widget.currentUserId, widget.receiverId);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.receiverProfile.isNotEmpty
                  ? NetworkImage(widget.receiverProfile)
                  : null,
              child: widget.receiverProfile.isEmpty
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(widget.receiverName, style: _appBarTitleStyle),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("messages")
                  .where("chatRoomID", isEqualTo: chatRoomId)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No messages yet. Say hi!",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: _primaryFontFamily,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data["senderID"] == widget.currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: isMe ? myColor : otherColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isMe ? 18 : 4),
                            topRight: Radius.circular(isMe ? 4 : 18),
                            bottomLeft: const Radius.circular(18),
                            bottomRight: const Radius.circular(18),
                          ),
                        ),
                        child: Text(
                          data["message"] ?? "",
                          style: _messageTextStyle.copyWith(color: isMe ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isDark ? Colors.grey.shade900 : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: _messageTextStyle.copyWith(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: _inputHintStyle,
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: myColor, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: myColor,
                  borderRadius: BorderRadius.circular(25),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: sendMessage,
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Icon(Icons.send_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
