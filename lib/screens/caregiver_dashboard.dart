import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class CaregiverDashboard extends StatelessWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkTheme;

  CaregiverDashboard({required this.onThemeChanged, required this.isDarkTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Caregiver Dashboard")),
      body: Center(child: Text("Dashboard Content")),
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
                      onThemeChanged: onThemeChanged,
                      isDarkTheme: isDarkTheme,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              title: Text("Logout"),
              leading: Icon(Icons.logout),
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('loggedInUser');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(
                      onThemeChanged: onThemeChanged,
                      isDarkTheme: isDarkTheme,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
