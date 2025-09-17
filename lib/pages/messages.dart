import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Assuming PlusJakartaSans is your app's default or you'll manage it via theme
// For direct use:
// import 'package:your_app_name/styles/app_text_styles.dart'; // Or similar

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController(); // For scrolling to bottom

  // --- Define Text Styles (Assuming "Plus Jakarta Sans" or from Theme) ---
  static const String _primaryFontFamily = 'PlusJakartaSans';

  static const TextStyle _appBarTitleStyle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600, // SemiBold
    color: Colors.black87, // Or your AppBar's foreground color
  );

  static const TextStyle _messageTextStyle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 15,
    height: 1.4, // Line height for readability
  );

  static const TextStyle _inputHintStyle = TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 15,
    color: Colors.grey,
  );
  // --- End Text Styles ---

  @override
  void initState() {
    super.initState();
    // Optional: Scroll to bottom when new messages arrive if needed,
    // though ListView.builder with reverse: true handles initial view.
  }

  void sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isNotEmpty) {
      _messageController.clear(); // Clear input field immediately

      try {
        await _firestore.collection("messages").add({
          "senderId": widget.currentUserId,
          "receiverId": widget.receiverId,
          "message": messageText,
          "timestamp": FieldValue.serverTimestamp(),
        });
        // Optionally, scroll to bottom after sending
        // _scrollToBottom();
      } catch (e) {
        print("Error sending message: $e");
        // Re-populate text field if send failed, or show error
        _messageController.text = messageText;
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Couldn't send message. Please try again."))
          );
        }
      }
    }
  }

  // void _scrollToBottom() {
  //   if (_scrollController.hasClients) {
  //     _scrollController.animateTo(
  //       0.0, // For reverse: true, 0.0 is the bottom
  //       duration: const Duration(milliseconds: 300),
  //       curve: Curves.easeOut,
  //     );
  //   }
  // }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the current theme is light or dark for adaptive colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final myMessageColor = isDarkMode ? Colors.green.shade700 : const Color(0xFF4CAF50); // Your theme green
    final otherMessageColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final myMessageTextColor = Colors.white;
    final otherMessageTextColor = isDarkMode ? Colors.white70 : Colors.black87;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey.shade100, // Subtle background
      appBar: AppBar(
        elevation: 1, // Subtle shadow
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black, // For back button and icons
        titleSpacing: 0, // Remove default title spacing if CircleAvatar is large
        title: Row(
          children: [
            CircleAvatar(
              radius: 18, // Slightly smaller avatar in AppBar
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
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("messages")
                  .where("senderId", isEqualTo: widget.currentUserId)
                  .where("receiverId", isEqualTo: widget.receiverId)
                  .orderBy("timestamp", descending: true) // This might need adjustment for two-way chat
                  .snapshots(),
              // NOTE: For a two-way chat, you usually need two queries or a more complex query
              // to get messages where (sender==A && receiver==B) OR (sender==B && receiver==A)
              // The provided filter in `snapshot.data!.docs.where(...)` handles this client-side.
              // For better performance with many messages, consider structuring Firestore data
              // or using server-side filtering if possible.
              //
              // A more robust Firestore query structure for chats often involves a chat_rooms collection
              // and then messages subcollection within each room.
              // Example:
              // String chatRoomId = getChatRoomId(widget.currentUserId, widget.receiverId);
              // stream: _firestore.collection("chat_rooms").doc(chatRoomId).collection("messages").orderBy("timestamp", descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  // You might still want to fetch messages where current user is receiver
                  // This current query only gets messages SENT BY currentUserId to receiverId.
                  // The .where() clause below filters for both directions.
                  // If you want to show "No messages yet", this is the place.
                }

                // Filtering messages for the current conversation
                final messages = snapshot.data?.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // This condition ensures we only show messages between the two users
                  return (data["senderId"] == widget.currentUserId &&
                      data["receiverId"] == widget.receiverId) ||
                      (data["senderId"] == widget.receiverId &&
                          data["receiverId"] == widget.currentUserId);
                }).toList() ?? [];

                if (messages.isEmpty) {
                  return Center(
                      child: Text(
                        "No messages yet. Say hi!",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontFamily: _primaryFontFamily),
                      ));
                }


                return ListView.builder(
                  reverse: true, // Shows latest messages at the bottom
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data["senderId"] == widget.currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75, // Max width for bubbles
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                            color: isMe ? myMessageColor : otherMessageColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isMe ? 18 : 4),  // Different rounding for "my" vs "other"
                              topRight: Radius.circular(isMe ? 4 : 18),
                              bottomLeft: const Radius.circular(18),
                              bottomRight: const Radius.circular(18),
                            ),
                            boxShadow: [ // Subtle shadow for depth
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              )
                            ]
                        ),
                        child: Text(
                          data["message"] ?? "",
                          style: _messageTextStyle.copyWith(
                            color: isMe ? myMessageTextColor : otherMessageTextColor,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900 : Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 5,
                  color: Colors.black.withOpacity(0.05),
                )
              ],
            ),
            child: SafeArea( // Ensures padding for notches, etc.
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: _messageTextStyle.copyWith(color: isDarkMode ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: _inputHintStyle,
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25), // Rounded input field
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: myMessageColor, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => sendMessage(), // Send on keyboard submit
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material( // For InkWell ripple effect
                      color: myMessageColor,
                      borderRadius: BorderRadius.circular(25),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: sendMessage,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Icon(
                            Icons.send_rounded, // Rounded send icon
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

