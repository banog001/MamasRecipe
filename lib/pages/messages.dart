import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Dietitians/dietitianPublicProfile.dart';


// --- Theme Helpers (Copied from other files) ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _textColorOnPrimary = Colors.white;

Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.white; // Changed to white

Color _cardBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.white;

Color _textColorPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black87;

Color _textColorSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.black54;

TextStyle _getTextStyle(
    BuildContext context, {
      double fontSize = 16,
      FontWeight fontWeight = FontWeight.normal,
      Color? color,
      String fontFamily = _primaryFontFamily,
      double? letterSpacing,
      FontStyle? fontStyle,
      double? height, // Added height parameter
    }) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final defaultTextColor =
      color ?? (isDarkMode ? Colors.white70 : Colors.black87);
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: defaultTextColor,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    height: height, // Use height parameter
  );
}
// --- End Theme Helpers ---

// --- Background Shapes Widget ---
Widget _buildBackgroundShapes(BuildContext context) {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: _scaffoldBgColor(context), // Use theme background color
    child: Stack(
      children: [
        Positioned(
          top: -100,
          left: -150,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -120,
          right: -180,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
  );
}
// --- End Background Shapes Widget ---

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

  // Add this method to your State class, after the build method

  Widget _buildChatBackgroundShapes(context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.green.shade800 : Colors.green.shade100;

    return Positioned.fill(
      child: Container(
        // This is the base color of the chat background
        color: isDark ? Colors.black : Colors.grey.shade100,
        child: Stack(
          children: [
// --- REPLACE with this ---
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
// --- End of replacement ---
          ],
        ),
      ),
    );
  }

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
    // --- Variables (no changes here) ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myColor = isDark ? Colors.green.shade700 : const Color(0xFF4CAF50);
    final otherColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    final chatRoomId = getChatRoomId(widget.currentUserId, widget.receiverId);

    return Scaffold(
      // IMPORTANT: You might want to make this transparent if your
      // _buildChatBackgroundShapes() is a full background.
      backgroundColor: Colors.transparent,

      // --- AppBar (no changes here) ---
      appBar: AppBar(
        elevation: 2,
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
                      style: _appBarTitleStyle, // Assuming _appBarTitleStyle is defined
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      // Using the refactored dialog method from our last conversation
                      _showUserProfileDialog(context);
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

      // --- BODY (This is the changed part) ---
      body: Stack(
        children: [
          // 1. Your new background shapes method
          // (Make sure you have defined this method in your State class)
          _buildChatBackgroundShapes(context),

          // 2. Your original Column containing the chat and input
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore // Assuming _firestore is defined
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
                            fontFamily: _primaryFontFamily, // Assuming _primaryFontFamily is defined
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController, // Assuming _scrollController is defined
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
                              style: _messageTextStyle.copyWith(color: isMe ? Colors.white : Colors.black87), // Assuming _messageTextStyle is defined
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // --- Message Input (no changes here) ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                // This color is important so the input field isn't transparent
                color: isDark ? Colors.grey.shade900 : Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController, // Assuming _messageController is defined
                        style: _messageTextStyle.copyWith(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: _inputHintStyle, // Assuming _inputHintStyle is defined
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: myColor, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => sendMessage(), // Assuming sendMessage is defined
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: myColor,
                      borderRadius: BorderRadius.circular(25),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: sendMessage, // Assuming sendMessage is defined
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
        ],
      ),
    );
  }

  // --- NEW, Extracted Method ---
// Place this inside your State class, after the build method

  void _showUserProfileDialog(BuildContext context) {
    // --- All your original dialog code is moved here ---
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6), // Consistent barrier
      builder: (dialogContext) {
        // 'dialogContext' is the context for the dialog itself
        // 'context' (from the method parameter) is for navigating the main screen

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // Consistent radius
          ),
          backgroundColor: Colors.transparent, // Transparent background
          child: ClipRRect( // Clip for background shapes
            borderRadius: BorderRadius.circular(24),
            child: Stack( // Stack for background shapes and content
              children: [
                // Background shapes (using the top-level helper)
                Positioned.fill(
                  child: Container(
                    color: _cardBgColor(dialogContext), // Base color from theme
                    child: Stack(
                      children: [
// --- REPLACE with this ---
                        Positioned(
                          top: -100, // Moves further up
                          right: -120, // Moves to the right
                          child: Container(
                            width: 300, // Larger
                            height: 300,
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(150.0), // 👈 FIX
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20, // Moves *inside* the bottom edge
                          left: -80, // Moves further left
                          child: Container(
                            width: 150, // Smaller
                            height: 150,
                            decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(75.0), // 👈 FIX
                              ),
                          ),
                        ),
// --- End of replacement ---
                      ],
                    ),
                  ),
                ),
                // Dialog Content
                Padding(
                  padding: const EdgeInsets.all(32.0), // Consistent padding
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Profile Avatar
                      CircleAvatar(
                        radius: 40, // Slightly larger
                        backgroundColor: _primaryColor.withOpacity(0.1),
                        backgroundImage: widget.receiverProfile.isNotEmpty
                            ? NetworkImage(widget.receiverProfile)
                            : null,
                        child: widget.receiverProfile.isEmpty
                            ? Icon(Icons.person_outline, size: 40, color: _primaryColor.withOpacity(0.8))
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Dietitian Name
                      Text(
                        widget.receiverName,
                        textAlign: TextAlign.center,
                        style: _getTextStyle(
                          dialogContext,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _textColorPrimary(dialogContext),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- Buttons ---

                      // View Profile Button (Outlined Style)
                      SizedBox(
                        width: double.infinity,
                        height: 52, // Slightly taller buttons
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryColor,
                            side: const BorderSide(color: _primaryColor, width: 1.5),
                            shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16),),
                          ),
                          onPressed: () {
                            Navigator.pop(dialogContext); // Close dialog first
                            Navigator.push(
                              context, // Use original 'context' for navigation
                              MaterialPageRoute(
                                builder: (context) => DietitianPublicProfile( // Assuming DietitianPublicProfile is a valid widget
                                  dietitianId: widget.receiverId,
                                  dietitianName: widget.receiverName,
                                  dietitianProfile: widget.receiverProfile,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility_outlined, size: 20),
                          label: Text("View Profile", style: _getTextStyle(dialogContext, fontSize: 15, fontWeight: FontWeight.bold, color: _primaryColor)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Request Appointment Button (Elevated Style)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasPendingAppointment ? Colors.grey.shade400 : _primaryColor, // Conditional color
                            foregroundColor: _textColorOnPrimary,
                            shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16),),
                            elevation: _hasPendingAppointment ? 0 : 4, // Conditional elevation
                          ),
                          // Disable button if pending or submitting
                          onPressed: (_hasPendingAppointment || _isSubmittingRequest) ? null : () {
                            Navigator.pop(dialogContext); // Close dialog
                            _requestAppointment(); // Assuming _requestAppointment is defined
                          },
                          icon: _isSubmittingRequest // Show loading indicator
                              ? Container(
                            width: 20, height: 20,
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                              : Icon( _hasPendingAppointment ? Icons.hourglass_top_rounded : Icons.calendar_month_outlined, size: 20),
                          label: Text(
                            _isSubmittingRequest
                                ? "Sending..."
                                : _hasPendingAppointment
                                ? "Request Pending"
                                : "Request Appointment",
                            style: _getTextStyle(dialogContext, fontSize: 15, fontWeight: FontWeight.bold, color: _textColorOnPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16), // Spacing for close button

                      // Close Button (TextButton style)
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text("Close", style: _getTextStyle(dialogContext, color: _textColorSecondary(dialogContext))),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    // --- End of your original dialog code ---
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}