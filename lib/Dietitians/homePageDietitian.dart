import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

const String _primaryFontFamily = 'PlusJakartaSans';
const Color _primaryColor = Color(0xFF4CAF50);
const Color _accentColor = Color(0xFF81C784);
const Color _textColorOnPrimary = Colors.white;

Color _scaffoldBgColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : Colors.grey.shade50;

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
    }) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? _textColorPrimary(context),
    fontFamily: _primaryFontFamily,
  );
}

class HomePageDietitian extends StatefulWidget {
  const HomePageDietitian({super.key});

  @override
  State<HomePageDietitian> createState() => _HomePageDietitianState();
}

class _HomePageDietitianState extends State<HomePageDietitian> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _DashboardPage(scaffoldKey: _scaffoldKey),
      const _SchedulePage(),
      const _MessagesPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _scaffoldBgColor(context),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: _textColorOnPrimary),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          _getPageTitle(),
          style: const TextStyle(
            color: _textColorOnPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: _primaryFontFamily,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: _textColorOnPrimary),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircleAvatar(
                    backgroundColor: _textColorOnPrimary,
                    child: Icon(Icons.person, color: _primaryColor),
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final profileUrl = userData?['profile'] ?? '';

                return GestureDetector(
                  onTap: () {
                    // Navigate to profile or show profile menu
                  },
                  child: CircleAvatar(
                    backgroundColor: _textColorOnPrimary,
                    backgroundImage: profileUrl.isNotEmpty
                        ? NetworkImage(profileUrl)
                        : null,
                    child: profileUrl.isEmpty
                        ? const Icon(Icons.person, color: _primaryColor)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: _cardBgColor(context),
          selectedItemColor: _primaryColor,
          unselectedItemColor: _textColorSecondary(context),
          selectedLabelStyle: const TextStyle(
            fontFamily: _primaryFontFamily,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: _primaryFontFamily,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              activeIcon: Icon(Icons.message),
              label: 'Messages',
            ),
          ],
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Schedule';
      case 2:
        return 'Messages';
      default:
        return 'Dietitian';
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _cardBgColor(context),
      child: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return DrawerHeader(
                  decoration: const BoxDecoration(color: _primaryColor),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: _textColorOnPrimary,
                        child: Icon(Icons.person, size: 40, color: _primaryColor),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading...',
                        style: _getTextStyle(
                          context,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textColorOnPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final firstName = userData?['firstName'] ?? 'Dietitian';
              final lastName = userData?['lastName'] ?? '';
              final email = userData?['email'] ?? 'No email';
              final profileUrl = userData?['profile'] ?? '';

              return DrawerHeader(
                decoration: const BoxDecoration(color: _primaryColor),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: _textColorOnPrimary,
                      backgroundImage: profileUrl.isNotEmpty
                          ? NetworkImage(profileUrl)
                          : null,
                      child: profileUrl.isEmpty
                          ? const Icon(Icons.person, size: 40, color: _primaryColor)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$firstName $lastName',
                      style: _getTextStyle(
                        context,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textColorOnPrimary,
                      ),
                    ),
                    Text(
                      email,
                      style: _getTextStyle(
                        context,
                        fontSize: 12,
                        color: _textColorOnPrimary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: _primaryColor),
            title: Text('Dashboard', style: _getTextStyle(context)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: _primaryColor),
            title: Text('Schedule', style: _getTextStyle(context)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.message, color: _primaryColor),
            title: Text('Messages', style: _getTextStyle(context)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: _primaryColor),
            title: Text('Settings', style: _getTextStyle(context)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: _getTextStyle(context, color: Colors.red),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const _DashboardPage({required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back!',
            style: _getTextStyle(
              context,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s your overview for today',
            style: _getTextStyle(
              context,
              fontSize: 14,
              color: _textColorSecondary(context),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Clients',
                  '24',
                  Icons.people,
                  _primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Appointments',
                  '8',
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Meal Plans',
                  '15',
                  Icons.restaurant_menu,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Messages',
                  '12',
                  Icons.message,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Activity',
            style: _getTextStyle(
              context,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityCard(
            context,
            'New client registered',
            'John Doe joined your program',
            '2 hours ago',
            Icons.person_add,
            _primaryColor,
          ),
          const SizedBox(height: 12),
          _buildActivityCard(
            context,
            'Appointment scheduled',
            'Meeting with Sarah Smith at 3:00 PM',
            '4 hours ago',
            Icons.calendar_today,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildActivityCard(
            context,
            'Meal plan updated',
            'Updated plan for Mike Johnson',
            '1 day ago',
            Icons.restaurant_menu,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: _getTextStyle(
                context,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: _getTextStyle(
                context,
                fontSize: 12,
                color: _textColorSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
      BuildContext context,
      String title,
      String subtitle,
      String time,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _cardBgColor(context),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: _getTextStyle(context, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: _getTextStyle(
            context,
            fontSize: 12,
            color: _textColorSecondary(context),
          ),
        ),
        trailing: Text(
          time,
          style: _getTextStyle(
            context,
            fontSize: 11,
            color: _textColorSecondary(context),
          ),
        ),
      ),
    );
  }
}

class _SchedulePage extends StatefulWidget {
  const _SchedulePage();

  @override
  State<_SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<_SchedulePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: _cardBgColor(context),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: _primaryColor,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: _primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonDecoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                formatButtonTextStyle: const TextStyle(
                  color: _primaryColor,
                  fontFamily: _primaryFontFamily,
                ),
                titleTextStyle: _getTextStyle(
                  context,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Upcoming Appointments',
            style: _getTextStyle(
              context,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildAppointmentCard(
            context,
            'Sarah Smith',
            'Initial Consultation',
            '10:00 AM - 11:00 AM',
            'https://via.placeholder.com/150',
          ),
          const SizedBox(height: 12),
          _buildAppointmentCard(
            context,
            'John Doe',
            'Follow-up Session',
            '2:00 PM - 3:00 PM',
            'https://via.placeholder.com/150',
          ),
          const SizedBox(height: 12),
          _buildAppointmentCard(
            context,
            'Mike Johnson',
            'Meal Plan Review',
            '4:00 PM - 5:00 PM',
            'https://via.placeholder.com/150',
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
      BuildContext context,
      String name,
      String type,
      String time,
      String imageUrl,
      ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _cardBgColor(context),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: _primaryColor.withOpacity(0.2),
          backgroundImage: NetworkImage(imageUrl),
        ),
        title: Text(
          name,
          style: _getTextStyle(context, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              type,
              style: _getTextStyle(
                context,
                fontSize: 13,
                color: _textColorSecondary(context),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: _primaryColor),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: _getTextStyle(
                    context,
                    fontSize: 12,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: _primaryColor),
          onPressed: () {},
        ),
      ),
    );
  }
}

class _MessagesPage extends StatefulWidget {
  const _MessagesPage();

  @override
  State<_MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<_MessagesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: _cardBgColor(context),
          child: TabBar(
            controller: _tabController,
            labelColor: _primaryColor,
            unselectedLabelColor: _textColorSecondary(context),
            indicatorColor: _primaryColor,
            labelStyle: const TextStyle(
              fontFamily: _primaryFontFamily,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Chats'),
              Tab(text: 'Notifications'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildChatsList(),
              _buildNotificationsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: 'user')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primaryColor),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: _primaryColor.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: _getTextStyle(context, fontSize: 18),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            final firstName = user['firstName'] ?? 'User';
            final lastName = user['lastName'] ?? '';
            final profileUrl = user['profile'] ?? '';
            final status = user['status'] ?? 'offline';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: _cardBgColor(context),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _primaryColor.withOpacity(0.2),
                      backgroundImage: profileUrl.isNotEmpty
                          ? NetworkImage(profileUrl)
                          : null,
                      child: profileUrl.isEmpty
                          ? const Icon(Icons.person, color: _primaryColor)
                          : null,
                    ),
                    if (status.toLowerCase() == 'online')
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _cardBgColor(context),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  '$firstName $lastName',
                  style: _getTextStyle(context, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Tap to start conversation',
                  style: _getTextStyle(
                    context,
                    fontSize: 13,
                    color: _textColorSecondary(context),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: _primaryColor),
                onTap: () {
                  // Navigate to chat screen
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationsList() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildNotificationCard(
          context,
          'New Appointment',
          'Sarah Smith booked an appointment for tomorrow at 10:00 AM',
          '2 hours ago',
          Icons.calendar_today,
          Colors.blue,
        ),
        _buildNotificationCard(
          context,
          'Message Received',
          'John Doe sent you a message',
          '4 hours ago',
          Icons.message,
          _primaryColor,
        ),
        _buildNotificationCard(
          context,
          'Meal Plan Completed',
          'Mike Johnson completed his meal plan for the week',
          '1 day ago',
          Icons.check_circle,
          Colors.green,
        ),
        _buildNotificationCard(
          context,
          'Payment Received',
          'Payment of \$150 received from Emma Wilson',
          '2 days ago',
          Icons.payment,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildNotificationCard(
      BuildContext context,
      String title,
      String message,
      String time,
      IconData icon,
      Color color,
      ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _cardBgColor(context),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: _getTextStyle(context, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message,
              style: _getTextStyle(
                context,
                fontSize: 13,
                color: _textColorSecondary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: _getTextStyle(
                context,
                fontSize: 11,
                color: _textColorSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}