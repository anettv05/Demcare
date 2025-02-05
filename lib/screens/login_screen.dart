import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'doctor_dashboard.dart';
import 'caregiver_dashboard.dart';
import 'settings_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkTheme;

  LoginScreen({required this.onThemeChanged, required this.isDarkTheme});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _staySignedIn = false;

  Future<void> _login() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = _usernameController.text.trim();
    String enteredPassword = _passwordController.text.trim();
    String? storedPassword = prefs.getString('user_${username}_password');
    String? role = prefs.getString('user_${username}_role');

    if (storedPassword != null && storedPassword == enteredPassword) {
      await prefs.setString('loggedInUser', username);
      if (role == 'Doctor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDashboard(
              onThemeChanged: widget.onThemeChanged,
              isDarkTheme: widget.isDarkTheme,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CaregiverDashboard(
              onThemeChanged: widget.onThemeChanged,
              isDarkTheme: widget.isDarkTheme,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid credentials!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _usernameController, decoration: InputDecoration(labelText: "Username")),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            Row(
              children: [
                Checkbox(
                  value: _staySignedIn,
                  onChanged: (value) => setState(() => _staySignedIn = value!),
                ),
                Text("Stay signed in")
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text("Login")),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SignUpScreen()),
              ),
              child: Text("Don't have an account? Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
