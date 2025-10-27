import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Dietitians/dietitianPublicProfile.dart';
import 'package:mamas_recipe/widget/custom_snackbar.dart';

// --- THEME HELPERS ---
const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _textColorOnPrimary = Colors.white;

Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white;

Color _cardBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white;

Color _textColorPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87;

Color _textColorSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54;

TextStyle _getTextStyle(
    BuildContext context, {
      double fontSize = 16,
      FontWeight fontWeight = FontWeight.normal,
      Color? color,
      String fontFamily = _primaryFontFamily,
      double? letterSpacing,
      FontStyle? fontStyle,
      double? height,
    }) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final defaultTextColor = color ?? (isDarkMode ? Colors.white70 : Colors.black87);
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: defaultTextColor,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    height: height,
  );
}

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
  bool _hasPendingMealPlan = false; // ✅ New state variable
  bool _isReceiverAdmin = false;

  @override
  void initState() {
    super.initState();
    fetchCurrentUserName();
    _listenToPendingAppointment();
    _listenToPendingMealPlan(); // ✅ Listen to meal plan requests
    _checkIfReceiverIsAdmin();
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

  Future<void> _checkIfReceiverIsAdmin() async {
    try {
      final doc = await _firestore.collection("Users").doc(widget.receiverId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final role = (data["role"] ?? "").toString().toLowerCase();
        if (mounted) {
          setState(() {
            _isReceiverAdmin = role == "admin";
          });
        }
      }
    } catch (e) {
      print("Error checking receiver role: $e");
    }
  }

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

  // ✅ New method to listen to pending meal plan requests
  void _listenToPendingMealPlan() {
    _firestore
        .collection('mealPlanRequests')
        .where('clientId', isEqualTo: widget.currentUserId)
        .where('dietitianId', isEqualTo: widget.receiverId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _hasPendingMealPlan = snapshot.docs.isNotEmpty;
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
    } catch (e) {
      print("Error adding notification: $e");
    }

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _requestAppointment() async {
    if (currentUserName.isEmpty) {
      CustomSnackBar.show(
        context,
        'User data not loaded yet',
        backgroundColor: Colors.redAccent,
        icon: Icons.lock_outline,
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isSubmittingRequest = true;
      });
    }

    try {
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
        CustomSnackBar.show(
          context,
          'Appointment request sent successfully!',
          backgroundColor: _primaryColor,
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      print('Error requesting appointment: $e');
      if (mounted) {
        setState(() {
          _isSubmittingRequest = false;
        });
        CustomSnackBar.show(
          context,
          'Error: $e',
          backgroundColor: Colors.redAccent,
          icon: Icons.error_outline,
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.receiverProfile.isNotEmpty ? NetworkImage(widget.receiverProfile) : null,
              child: widget.receiverProfile.isEmpty ? const Icon(Icons.person, size: 20) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.receiverName,
                      style: const TextStyle(
                        fontFamily: _primaryFontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Only show info button if receiver is NOT an admin
                  if (!_isReceiverAdmin)
                    GestureDetector(
                      onTap: () {
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
      body: Stack(
        children: [
          _buildChatBackgroundShapes(context),
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
                              messageText,
                              style: TextStyle(
                                fontFamily: _primaryFontFamily,
                                fontSize: 15,
                                height: 1.4,
                                color: isMe ? Colors.white : Colors.black87,
                              ),
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
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: const TextStyle(fontFamily: _primaryFontFamily, fontSize: 15, color: Colors.grey),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: myColor, width: 1.5)),
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
        ],
      ),
    );
  }

  Widget _buildChatBackgroundShapes(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: Container(
        color: isDark ? Colors.black : Colors.grey.shade100,
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -50,
              child: Transform.rotate(
                angle: -0.8,
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
                angle: 0.5,
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

  void _showUserProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: _cardBgColor(dialogContext),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -100,
                          right: -120,
                          child: Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(150.0),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: -80,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(75.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: _firestore
                        .collection('Users')
                        .doc(widget.receiverId)
                        .collection('subscriber')
                        .doc(widget.currentUserId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final isSubscribed = snapshot.hasData && snapshot.data!.exists;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: _primaryColor.withOpacity(0.1),
                            backgroundImage:
                            widget.receiverProfile.isNotEmpty ? NetworkImage(widget.receiverProfile) : null,
                            child: widget.receiverProfile.isEmpty
                                ? Icon(Icons.person_outline, size: 40, color: _primaryColor.withOpacity(0.8))
                                : null,
                          ),
                          const SizedBox(height: 16),
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
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryColor,
                                side: const BorderSide(color: _primaryColor, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () {
                                Navigator.pop(dialogContext);
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
                              icon: const Icon(Icons.visibility_outlined, size: 20),
                              label: Text(
                                "View Profile",
                                style: _getTextStyle(
                                  dialogContext,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _hasPendingAppointment ? Colors.grey.shade400 : _primaryColor,
                                foregroundColor: _textColorOnPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: _hasPendingAppointment ? 0 : 4,
                              ),
                              onPressed: (_hasPendingAppointment || _isSubmittingRequest) ? null : () {
                                Navigator.pop(dialogContext);
                                _requestAppointment();
                              },
                              icon: _isSubmittingRequest
                                  ? Container(
                                width: 20,
                                height: 20,
                                padding: const EdgeInsets.all(2.0),
                                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              )
                                  : Icon(
                                  _hasPendingAppointment ? Icons.hourglass_top_rounded : Icons.calendar_month_outlined,
                                  size: 20),
                              label: Text(
                                _isSubmittingRequest
                                    ? "Sending..."
                                    : _hasPendingAppointment
                                    ? "Request Pending"
                                    : "Request Appointment",
                                style: _getTextStyle(
                                  dialogContext,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _textColorOnPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // ✅ Updated meal plan button with pending check
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (!isSubscribed || _hasPendingMealPlan)
                                    ? Colors.grey.shade400
                                    : _primaryColor,
                                foregroundColor: _textColorOnPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: (isSubscribed && !_hasPendingMealPlan) ? 4 : 0,
                              ),
                              onPressed: (isSubscribed && !_hasPendingMealPlan) ? () {
                                Navigator.pop(dialogContext);
                                _requestPersonalizedMealPlan();
                              } : null,
                              icon: Icon(
                                !isSubscribed
                                    ? Icons.lock_outline
                                    : _hasPendingMealPlan
                                    ? Icons.hourglass_top_rounded
                                    : Icons.restaurant_menu_outlined,
                                size: 20,
                              ),
                              label: Text(
                                !isSubscribed
                                    ? "Subscribe to Request Meal Plan"
                                    : _hasPendingMealPlan
                                    ? "Meal Plan Request Pending"
                                    : "Request Personalized Meal Plan",
                                style: _getTextStyle(
                                  dialogContext,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _textColorOnPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text("Close", style: _getTextStyle(dialogContext, color: _textColorSecondary(dialogContext))),
                          )
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _requestPersonalizedMealPlan() async {
    if (currentUserName.isEmpty) {
      CustomSnackBar.show(
        context,
        'User data not loaded yet',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
      return;
    }

    try {
      await _firestore.collection('mealPlanRequests').add({
        'clientId': widget.currentUserId,
        'clientName': currentUserName,
        'clientEmail': currentUserEmail,
        'dietitianId': widget.receiverId,
        'dietitianName': widget.receiverName,
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
        'message': '',
      });

      await _firestore
          .collection('Users')
          .doc(widget.receiverId)
          .collection('notifications')
          .add({
        'title': 'Meal Plan Request',
        'message': '$currentUserName requested a personalized meal plan',
        'senderId': widget.currentUserId,
        'senderName': currentUserName,
        'type': 'mealPlanRequest',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Meal plan request sent successfully!',
          backgroundColor: _primaryColor,
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      print('Error requesting meal plan: $e');
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error sending request: $e',
          backgroundColor: Colors.redAccent,
          icon: Icons.error_outline,
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}