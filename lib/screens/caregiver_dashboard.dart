import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'settings_screen.dart';
import 'login_screen.dart';

class CaregiverDashboard extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkTheme;

  CaregiverDashboard({required this.onThemeChanged, required this.isDarkTheme});

  @override
  _CaregiverDashboardState createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  List<Map<String, String>> patients = [];
  String loggedInUser = "";

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    loggedInUser = prefs.getString('loggedInUser') ?? '';
    List<String> storedPatients = prefs.getStringList('patients_$loggedInUser') ?? [];
    setState(() {
      patients = storedPatients.map((patientJson) {
        return Map<String, String>.from(json.decode(patientJson));
      }).toList();
    });
  }

  Future<void> _addOrUpdatePatient(Map<String, String> patient, {bool isEditing = false, int? index}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedPatients = prefs.getStringList('patients_$loggedInUser') ?? [];

    if (isEditing && index != null) {
      storedPatients[index] = json.encode(patient);
    } else {
      storedPatients.add(json.encode(patient));
    }

    await prefs.setStringList('patients_$loggedInUser', storedPatients);
    _loadPatients();
  }

  Future<void> _deletePatient(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedPatients = prefs.getStringList('patients_$loggedInUser') ?? [];
    storedPatients.removeAt(index);
    await prefs.setStringList('patients_$loggedInUser', storedPatients);
    _loadPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Caregiver Dashboard")),
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
                      onThemeChanged: widget.onThemeChanged,
                      isDarkTheme: widget.isDarkTheme,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: patients.isEmpty
          ? Center(child: Text("No patients added yet"))
          : ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          var patient = patients[index];
          return ListTile(
            title: Text(patient["name"] ?? "Unknown"),
            subtitle: Text("Status: ${patient["status"] ?? "Unknown"}"),
            trailing: patient["status"] == "Out of Range"
                ? Icon(Icons.warning, color: Colors.red)
                : Icon(Icons.check_circle, color: Colors.green),
            onTap: () => _viewPatientDetails(patient, index),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditPatientDialog(),
        child: Icon(Icons.add),
      ),
    );
  }

  void _viewPatientDetails(Map<String, String> patient, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(
          patient: patient,
          onDelete: () {
            _deletePatient(index);
            Navigator.pop(context);
          },
          onEdit: () {
            Navigator.pop(context);
            _showAddOrEditPatientDialog(patient: patient, index: index);
          },
        ),
      ),
    );
  }

  void _showAddOrEditPatientDialog({Map<String, String>? patient, int? index}) {
    final TextEditingController nameController = TextEditingController(text: patient?['name'] ?? "");
    final TextEditingController ageController = TextEditingController(text: patient?['age'] ?? "");
    final TextEditingController heightController = TextEditingController(text: patient?['height'] ?? "");
    final TextEditingController weightController = TextEditingController(text: patient?['weight'] ?? "");
    final TextEditingController caregiverController = TextEditingController(text: patient?['caregiver'] ?? "");
    final TextEditingController rfidController = TextEditingController(text: patient?['rfid'] ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(patient == null ? "Add Patient" : "Edit Patient"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
              TextField(controller: ageController, decoration: InputDecoration(labelText: "Age"), keyboardType: TextInputType.number),
              TextField(controller: heightController, decoration: InputDecoration(labelText: "Height")),
              TextField(controller: weightController, decoration: InputDecoration(labelText: "Weight")),
              TextField(controller: caregiverController, decoration: InputDecoration(labelText: "Caregiver Contact")),
              TextField(controller: rfidController, decoration: InputDecoration(labelText: "RFID Mac Address")),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Map<String, String> newPatient = {
                "name": nameController.text,
                "age": ageController.text,
                "height": heightController.text,
                "weight": weightController.text,
                "caregiver": caregiverController.text,
                "rfid": rfidController.text,
                "status": "Unknown"
              };
              _addOrUpdatePatient(newPatient, isEditing: patient != null, index: index);
              Navigator.pop(context);
            },
            child: Text(patient == null ? "Add" : "Save"),
          ),
        ],
      ),
    );
  }
}
class PatientDetailsScreen extends StatelessWidget {
  final Map<String, String> patient;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  PatientDetailsScreen({required this.patient, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Patient Details"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "Delete") {
                onDelete();
                Navigator.pop(context);
              } else if (value == "Edit") {
                onEdit();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(value: "Edit", child: Text("Edit Details")),
              PopupMenuItem(value: "Delete", child: Text("Delete Patient")),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${patient["name"]}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Age: ${patient["age"]}"),
            Text("Height: ${patient["height"]}"),
            Text("Weight: ${patient["weight"]}"),
            Text("Caregiver Contact: ${patient["caregiver"]}"),
            Text("RFID Mac Address: ${patient["rfid"]}"),
            Text("Status: ${patient["status"]}"),
          ],
        ),
      ),
    );
  }
}
