import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkTheme;

  SettingsScreen({required this.onThemeChanged, required this.isDarkTheme});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String subscriptionPlan = "Free";
  String loggedInUser = "";
  bool isEditing = false;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUser = prefs.getString('loggedInUser') ?? '';
      _nameController.text = prefs.getString('user_${loggedInUser}_name') ?? '';
      _emailController.text = prefs.getString('user_${loggedInUser}_email') ?? '';
      _phoneController.text = prefs.getString('user_${loggedInUser}_phone') ?? '';
      subscriptionPlan = prefs.getString('user_${loggedInUser}_subscription') ?? 'Free';
      isDarkMode = prefs.getBool('isDarkTheme') ?? false;
    });
  }

  Future<void> _saveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_${loggedInUser}_name', _nameController.text);
    await prefs.setString('user_${loggedInUser}_email', _emailController.text);
    await prefs.setString('user_${loggedInUser}_phone', _phoneController.text);
    await prefs.setString('user_${loggedInUser}_subscription', subscriptionPlan);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Settings Saved")));
    setState(() {
      isEditing = false;
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
          isDarkTheme: isDarkMode,
        ),
      ),
          (route) => false,
    );
  }

  void _toggleTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', value);
    setState(() {
      isDarkMode = value;
    });
    widget.onThemeChanged(value);
  }

  Widget _buildSettingsItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  void _showAccountDetails() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text("Account Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        setState(() {
                          isEditing = !isEditing;
                        });
                      },
                    ),
                  ),
                  TextField(controller: _nameController, decoration: InputDecoration(labelText: "Full Name"), enabled: isEditing),
                  TextField(controller: _emailController, decoration: InputDecoration(labelText: "Email"), enabled: isEditing),
                  TextField(controller: _phoneController, decoration: InputDecoration(labelText: "Phone Number"), enabled: isEditing),
                  if (isEditing)
                    ElevatedButton(onPressed: _saveUserData, child: Text("Save Changes")),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
              Text("Subscription Plan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: subscriptionPlan,
                items: ["Free", "Premium", "Enterprise"].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) => setState(() => subscriptionPlan = newValue!),
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
      appBar: AppBar(title: Text("Settings")),
      body: ListView(
        children: [
          _buildSettingsItem("Account Details", Icons.person, _showAccountDetails),
          SwitchListTile(
            title: Text("Dark Mode"),
            value: isDarkMode,
            onChanged: _toggleTheme,
          ),
          _buildSettingsItem("Subscription Details", Icons.subscriptions, _showSubscriptionDetails),
          Divider(),
          _buildSettingsItem("Logout", Icons.logout, _logout),
        ],
      ),
    );
  }
}
