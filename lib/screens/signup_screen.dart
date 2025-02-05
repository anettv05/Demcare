import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _role = "Caregiver";

  Future<void> _signUp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Username and Password cannot be empty!")));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Passwords do not match!")));
      return;
    }

    // Save user data uniquely per username
    await prefs.setString('user_${username}_password', password);
    await prefs.setString('user_${username}_name', _nameController.text.trim());
    await prefs.setString('user_${username}_email', _emailController.text.trim());
    await prefs.setString('user_${username}_phone', _phoneController.text.trim());
    await prefs.setString('user_${username}_age', _ageController.text.trim());
    await prefs.setString('user_${username}_role', _role);

    // Save the logged-in user for autofill in settings
    await prefs.setString('loggedInUser', username);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Account created successfully!")));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          onThemeChanged: (bool) {},
          isDarkTheme: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: "Full Name")),
            TextField(controller: _usernameController, decoration: InputDecoration(labelText: "Username")),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: _phoneController, decoration: InputDecoration(labelText: "Phone Number")),
            TextField(controller: _ageController, decoration: InputDecoration(labelText: "Age"), keyboardType: TextInputType.number),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            TextField(controller: _confirmPasswordController, decoration: InputDecoration(labelText: "Confirm Password"), obscureText: true),
            SizedBox(height: 10),
            Row(
              children: [
                Text("Are you a:"),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _role,
                  items: ["Caregiver", "Doctor"].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) => setState(() => _role = newValue!),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _signUp, child: Text("Sign Up")),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                    onThemeChanged: (bool) {},
                    isDarkTheme: false,
                  ),
                ),
              ),
              child: Text("Already have an account? Log in"),
            ),
          ],
        ),
      ),
    );
  }
}
