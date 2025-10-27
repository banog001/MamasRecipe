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

  // --- NEW: Show User Info Dialog ---
  void _showUserInfoDialog() async {
    try {
      final doc = await _firestore.collection("Users").doc(widget.receiverId).get();

      if (!doc.exists || !mounted) return;

      final data = doc.data()!;
      final firstName = data['firstName'] ?? '';
      final lastName = data['lastName'] ?? '';
      final height = data['height']?.toString() ?? 'N/A';
      final weight = data['currentWeight']?.toString() ?? 'N/A';
      final activityLevel = data['activityLevel'] ?? 'N/A';
      final goals = data['goals'] ?? 'N/A';
      final age = data['age']?.toString() ?? 'N/A';
      final gender = data['gender'] ?? 'N/A';

      // Calculate BMI if height and weight are available
      String bmi = 'N/A';
      if (height != 'N/A' && weight != 'N/A') {
        try {
          final heightInMeters = double.parse(height) / 100;
          final weightInKg = double.parse(weight);
          final bmiValue = weightInKg / (heightInMeters * heightInMeters);
          bmi = bmiValue.toStringAsFixed(1);
        } catch (e) {
          bmi = 'N/A';
        }
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 16,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with profile
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _primaryColor,
                            _primaryColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: widget.receiverProfile.isNotEmpty
                                ? NetworkImage(widget.receiverProfile)
                                : null,
                            child: widget.receiverProfile.isEmpty
                                ? const Icon(Icons.person, size: 40, color: _primaryColor)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$firstName $lastName',
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$age years • $gender',
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body Information
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Health Information',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Physical Stats Grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.height,
                                  label: 'Height',
                                  value: '$height cm',
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.monitor_weight_outlined,
                                  label: 'Weight',
                                  value: '$weight kg',
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // BMI Card
                          _buildInfoCard(
                            icon: Icons.analytics_outlined,
                            label: 'BMI',
                            value: bmi,
                            isDark: isDark,
                            fullWidth: true,
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Fitness Profile',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Activity Level
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _primaryColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.directions_run,
                                    color: _primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Activity Level',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                          fontFamily: 'PlusJakartaSans',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        activityLevel,
                                        style: TextStyle(
                                          fontFamily: 'PlusJakartaSans',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Goals
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _primaryColor.withOpacity(0.15),
                                  _primaryColor.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _primaryColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.flag_outlined,
                                    color: _primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Goals',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                          fontFamily: 'PlusJakartaSans',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        goals,
                                        style: const TextStyle(
                                          fontFamily: 'PlusJakartaSans',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: _primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Close Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user info: $e')),
        );
      }
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _primaryColor,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
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
            Expanded(
              child: Text(
                widget.receiverName,
                style: _appBarTitleStyle.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        // --- NEW: Added info icon button ---
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'User Information',
            onPressed: _showUserInfoDialog,
          ),
        ],
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}