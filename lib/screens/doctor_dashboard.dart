import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';
import 'patients_screen.dart';
import 'logs_screen.dart';
import 'live_feed_screen.dart';
import 'login_screen.dart';

class DoctorDashboard extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkTheme;

  DoctorDashboard({required this.onThemeChanged, required this.isDarkTheme});

  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    LogsScreen(),
    PatientsScreen(),
    LiveFeedScreen()
  ];

  // A simple subscription plan state (default to 'Free' or any)
  String subscriptionPlan = "Free";

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUser');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          onThemeChanged: widget.onThemeChanged,
          isDarkTheme: widget.isDarkTheme,
        ),
      ),
          (route) => false,
    );
  }

  // Show subscription details in a bottom sheet
  void _showSubscriptionDetails() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Subscription Plan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: subscriptionPlan,
                items: ["Free", "Premium", "Enterprise"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    subscriptionPlan = newValue!;
                  });
                  // Optionally, persist to SharedPreferences if desired
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Doctor Dashboard"),
      ),
      body: _pages[_selectedIndex],
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text("Settings"),
              leading: Icon(Icons.settings),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      onThemeChanged: widget.onThemeChanged,
                      isDarkTheme: widget.isDarkTheme,
                    ),
                  ),
                );
              },
            ),
            // Subscription Details BELOW Settings
            ListTile(
              title: Text("Subscription"),
              leading: Icon(Icons.subscriptions),
              onTap: _showSubscriptionDetails,
            ),
            ListTile(
              title: Text("Logout"),
              leading: Icon(Icons.logout),
              onTap: _logout,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.article), label: "Log"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Patients"),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), label: "Live Feed"),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
