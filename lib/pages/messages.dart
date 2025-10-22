import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Dietitians/dietitianPublicProfile.dart';

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

  String currentUserName = "";
  String currentUserEmail = "";
  bool _isSubmittingRequest = false;
  bool _hasPendingAppointment = false;

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
    _listenToPendingAppointment();
  }

  void fetchCurrentUserName() async {
    final doc = await _firestore.collection("Users").doc(widget.currentUserId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        currentUserName = "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}".trim();
        currentUserEmail = data["email"] ?? "";
      });
    }
  }

  /// ✅ Listen to pending appointment status in real-time
  void _listenToPendingAppointment() {
    _firestore
        .collection('appointmentRequest')
        .where('clientId', isEqualTo: widget.currentUserId)
        .where('dietitianId', isEqualTo: widget.receiverId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _hasPendingAppointment = snapshot.docs.isNotEmpty;
        });
      }
    });
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
    try {
      await _firestore
          .collection("Users")
          .doc(widget.receiverId)
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
      print("✅ Notification added successfully");
    } catch (e) {
      print("❌ Error adding notification: $e");
    }

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// ✅ Request appointment from dietitian
  Future<void> _requestAppointment() async {
    if (currentUserName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not loaded yet')),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isSubmittingRequest = true;
      });
    }

    try {
      // Add to appointmentRequest collection
      await _firestore.collection('appointmentRequest').add({
        'clientId': widget.currentUserId,
        'clientName': currentUserName,
        'clientEmail': currentUserEmail,
        'dietitianId': widget.receiverId,
        'dietitianName': widget.receiverName,
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
        'message': '',
      });

      // Add notification to dietitian
      await _firestore
          .collection('Users')
          .doc(widget.receiverId)
          .collection('notifications')
          .add({
        'title': 'Appointment Request',
        'message': '$currentUserName requested an appointment with you',
        'senderId': widget.currentUserId,
        'senderName': currentUserName,
        'type': 'appointmentRequest',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _isSubmittingRequest = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment request sent successfully!'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error requesting appointment: $e');
      if (mounted) {
        setState(() {
          _isSubmittingRequest = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.receiverName,
                      style: _appBarTitleStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Text(
                            widget.receiverName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily: 'PlusJakartaSans',
                            ),
                          ),
                          content: const Text(
                            "Do you want to view this dietitian's public profile?",
                            style: TextStyle(fontFamily: 'PlusJakartaSans'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Close"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _hasPendingAppointment ? Colors.grey : Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _hasPendingAppointment ? null : () {
                                Navigator.pop(context);
                                _requestAppointment();
                              },
                              child: Text(_hasPendingAppointment ? "Your appointment is still pending" : "Request Appointment"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DietitianPublicProfile(
                                      dietitianId: widget.receiverId,
                                      dietitianName: widget.receiverName,
                                      dietitianProfile: widget.receiverProfile,
                                    ),
                                  ),
                                );
                              },
                              child: const Text("View Profile"),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.info_outline,
                        size: 30,
                        color: isDark ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                    final messageText = data["message"] ?? "";
                    final senderName = data["senderName"] ?? "";
                    final displayText = messageText;

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
                          displayText,
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}