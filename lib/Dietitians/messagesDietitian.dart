import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Theme Color Helper (Copied from messages.dart) ---
const Color _primaryColor = Color(0xFF4CAF50);

class MessagesPageDietitian extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String currentUserId;
  final String receiverProfile;

  const MessagesPageDietitian({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.currentUserId,
    required this.receiverProfile,
  });

  @override
  State<MessagesPageDietitian> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPageDietitian> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String currentUserName = "";

  // --- NEW: Copied from messages.dart ---
  Widget _buildChatBackgroundShapes(context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Note: _primaryColor is defined as a const at the top of the file.

    return Positioned.fill(
      child: Container(
        // This is the base color of the chat background
        color: isDark ? Colors.black : Colors.grey.shade100,
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -50,
              child: Transform.rotate(
                angle: -0.8, // Rotates counter-clockwise (in radians)
                child: Container(
                  width: 250,
                  height: 150,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              right: -50,
              child: Transform.rotate(
                angle: 0.5, // Rotates clockwise (in radians)
                child: Container(
                  width: 300,
                  height: 180,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(60),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- End of new code ---


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

  @override
  void initState() {
    super.initState();
    fetchCurrentUserName();
  }

  void fetchCurrentUserName() async {
    final doc =
    await _firestore.collection("Users").doc(widget.currentUserId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        currentUserName =
            "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}".trim();
      });
    }
  }

  String getChatRoomId(String userA, String userB) {
    return userA.compareTo(userB) <= 0 ? '$userA\_$userB' : '$userB\_$userA';
  }

  void sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUserName.isEmpty) return;

    _messageController.clear();
    final chatRoomId = getChatRoomId(widget.currentUserId, widget.receiverId);

    // Add message with senderName and receiverName
    await _firestore.collection("messages").add({
      "senderID": widget.currentUserId,
      "senderName": currentUserName,
      "receiverID": widget.receiverId,
      "receiverName": widget.receiverName,
      "message": text,
      "timestamp": FieldValue.serverTimestamp(),
      "chatRoomID": chatRoomId,
      "read": "false",
    });

    // Add notification
    await _firestore
        .collection("Users")
        .doc(widget.receiverId) // 👈 parent is receiver
        .collection("notifications")
        .add({
      "title": "New Message",
      "message": "$currentUserName: $text",
      "senderId": widget.currentUserId,
      "senderName": currentUserName,
      "receiverId": widget.receiverId,
      "receiverName": widget.receiverName,
      "receiverProfile": widget.receiverProfile,
      "type": "message",
      "isRead": false,
      "timestamp": FieldValue.serverTimestamp(),
    });

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
      // --- CHANGED: Made transparent to see the stack background ---
      backgroundColor: Colors.transparent,
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
      // --- CHANGED: Swapped Column for Stack ---
      body: Stack(
        children: [
          // 1. The new background
          _buildChatBackgroundShapes(context),

          // 2. The original Column
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection("messages")
                      .where("chatRoomID", isEqualTo: chatRoomId)
                      .orderBy("timestamp", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

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
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data =
                        docs[index].data() as Map<String, dynamic>;
                        final isMe = data["senderID"] == widget.currentUserId;
                        final messageText = data["message"] ?? "";
                        final senderName = data["senderName"] ?? "";
                        final displayText = messageText;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                                maxWidth:
                                MediaQuery.of(context).size.width * 0.75),
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
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
                              displayText,
                              style: _messageTextStyle.copyWith(
                                  color: isMe ? Colors.white : Colors.black87),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                // This color is important so the input isn't transparent
                color: isDark ? Colors.grey.shade900 : Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: _messageTextStyle.copyWith(
                            color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: _inputHintStyle,
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide:
                              BorderSide(color: myColor, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
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
                          child: Icon(Icons.send_rounded,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- NEW: Added dispose method for good practice ---
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}