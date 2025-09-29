import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DietitianSubscribersPage extends StatefulWidget {
  final String dietitianId;

  const DietitianSubscribersPage({super.key, required this.dietitianId});

  @override
  State<DietitianSubscribersPage> createState() => _DietitianSubscribersPageState();
}

class _DietitianSubscribersPageState extends State<DietitianSubscribersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'My Subscribers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subscriptions')
            .where('dietitianId', isEqualTo: widget.dietitianId)
            .where('status', isEqualTo: 'active')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No Active Subscribers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Users who subscribe to your meal plans will appear here',
                    style: TextStyle(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final subscription = snapshot.data!.docs[index];
              final data = subscription.data() as Map<String, dynamic>;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(data['userId'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(Icons.person)),
                        title: Text('Loading...'),
                      ),
                    );
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final userName = "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();
                  final userEmail = userData['email'] ?? 'No email';
                  final startDate = (data['startDate'] as Timestamp?)?.toDate();
                  final endDate = (data['endDate'] as Timestamp?)?.toDate();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF4CAF50),
                        backgroundImage: userData['profile'] != null && userData['profile'].toString().isNotEmpty
                            ? NetworkImage(userData['profile'])
                            : null,
                        child: userData['profile'] == null || userData['profile'].toString().isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        userName.isNotEmpty ? userName : 'Unknown User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userEmail),
                          if (startDate != null)
                            Text(
                              'Subscribed: ${DateFormat('MMM dd, yyyy').format(startDate)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          if (endDate != null)
                            Text(
                              'Expires: ${DateFormat('MMM dd, yyyy').format(endDate)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        // TODO: Navigate to user details or chat
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
