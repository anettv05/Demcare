import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math'; // for Random()

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

  // Define subscriptionPlan so it is no longer undefined
  String subscriptionPlan = "Free";

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

  Future<void> _addOrUpdatePatient(Map<String, String> patient,
      {bool isEditing = false, int? index}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedPatients =
        prefs.getStringList('patients_$loggedInUser') ?? [];

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
    List<String> storedPatients =
        prefs.getStringList('patients_$loggedInUser') ?? [];
    storedPatients.removeAt(index);
    await prefs.setStringList('patients_$loggedInUser', storedPatients);
    _loadPatients();
  }

  // Show subscription details in a bottom sheet with a dropdown for "Free/Premium/Enterprise"
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
                  // If you want to persist subscription plan, also store in SharedPreferences here
                },
              ),
            ],
          ),
        );
      },
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
    final TextEditingController nameController =
    TextEditingController(text: patient?['name'] ?? "");
    final TextEditingController ageController =
    TextEditingController(text: patient?['age'] ?? "");
    final TextEditingController heightController =
    TextEditingController(text: patient?['height'] ?? "");
    final TextEditingController weightController =
    TextEditingController(text: patient?['weight'] ?? "");
    final TextEditingController caregiverController =
    TextEditingController(text: patient?['caregiver'] ?? "");
    final TextEditingController rfidController =
    TextEditingController(text: patient?['rfid'] ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(patient == null ? "Add Patient" : "Edit Patient"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: ageController,
                decoration: InputDecoration(labelText: "Age"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: heightController,
                decoration: InputDecoration(labelText: "Height"),
              ),
              TextField(
                controller: weightController,
                decoration: InputDecoration(labelText: "Weight"),
              ),
              TextField(
                controller: caregiverController,
                decoration: InputDecoration(labelText: "Caregiver Contact"),
              ),
              TextField(
                controller: rfidController,
                decoration: InputDecoration(labelText: "RFID Mac Address"),
              ),
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
                // Keep status if editing; if adding, default to "Unknown"
                "status": patient?['status'] ?? "Unknown",
              };
              _addOrUpdatePatient(
                newPatient,
                isEditing: patient != null,
                index: index,
              );
              Navigator.pop(context);
            },
            child: Text(patient == null ? "Add" : "Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Caregiver Dashboard"),
      ),
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
            // Subscription Details BELOW Logout
            ListTile(
              title: Text("Subscription"),
              leading: Icon(Icons.subscriptions),
              onTap: _showSubscriptionDetails,
            ),
            Divider(),
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
}

class PatientDetailsScreen extends StatelessWidget {
  final Map<String, String> patient;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  PatientDetailsScreen({
    required this.patient,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final oxygenSaturation = 95 + random.nextInt(6);  // 95 to 100
    final respiratoryRate = 12 + random.nextInt(9);   // 12 to 20
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
            Text("Name: ${patient["name"]}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Age: ${patient["age"]}"),
            Text("Height: ${patient["height"]}"),
            Text("Weight: ${patient["weight"]}"),
            Text("Caregiver Contact: ${patient["caregiver"]}"),
            Text("RFID Mac Address: ${patient["rfid"]}"),
            Text("Status: ${patient["status"]}"),

            Text(
              "Heart Rate (BPM)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Heart Rate Graph
            Container(
              height: 250,
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey.shade300, strokeWidth: 0.5);
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(color: Colors.grey.shade300, strokeWidth: 0.5);
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 100), FlSpot(1, 105), FlSpot(2, 110),
                        FlSpot(3, 120), FlSpot(4, 140), FlSpot(5, 130),
                        FlSpot(6, 140), FlSpot(7, 120), FlSpot(8, 110),
                        FlSpot(9, 110), FlSpot(10, 105), FlSpot(11, 110),
                        FlSpot(12, 100), FlSpot(13, 105), FlSpot(14, 110),
                        FlSpot(15, 120), FlSpot(16, 140), FlSpot(17, 130),
                        FlSpot(18, 140), FlSpot(19, 120), FlSpot(20, 110),
                        FlSpot(21, 110), FlSpot(22, 105), FlSpot(23, 110),
                        FlSpot(24, 110), FlSpot(25, 105), FlSpot(26, 110),
                        FlSpot(27, 100), FlSpot(28, 105), FlSpot(29, 110),
                        FlSpot(30, 120), FlSpot(31, 140), FlSpot(32, 130),
                        FlSpot(33, 140), FlSpot(34, 120), FlSpot(35, 110),
                        FlSpot(36, 110), FlSpot(37, 105), FlSpot(38, 110),
                      ],
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Oxygen saturation
            Text(
              "Oxygen Saturation: $oxygenSaturation%",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            // Respiratory rate
            Text(
              "Respiratory Rate: $respiratoryRate breaths/min",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
