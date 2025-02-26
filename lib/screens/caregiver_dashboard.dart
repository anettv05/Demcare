import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'memory_test_screen.dart'; // Import the memory test screen

class CaregiverDashboard extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkTheme;

  CaregiverDashboard({required this.onThemeChanged, required this.isDarkTheme});

  @override
  _CaregiverDashboardState createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  // Patients list
  List<Map<String, String>> patients = [];
  // Logged-in user
  String loggedInUser = "";
  // Subscription plan (Free, Premium, Enterprise)
  String subscriptionPlan = "Free";

  // For beacon status fetching
  String serverIp = "192.168.61.162"; // Replace with your Raspberry Pi's IP
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    // Fetch beacon data on load
    fetchBeaconStatus();
    // Auto-refresh every 1 second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      fetchBeaconStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop the timer
    super.dispose();
  }

  /// Loads saved patient data from SharedPreferences.
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

  /// Adds or updates a patient record in SharedPreferences.
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

  /// Deletes a patient from SharedPreferences.
  Future<void> _deletePatient(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedPatients = prefs.getStringList('patients_$loggedInUser') ?? [];
    storedPatients.removeAt(index);
    await prefs.setStringList('patients_$loggedInUser', storedPatients);
    _loadPatients();
  }

  /// Fetches beacon data from the Raspberry Pi and updates each patient's status.
  Future<void> fetchBeaconStatus() async {
    try {
      final response = await http.get(Uri.parse('http://$serverIp:5000/get_status'));
      if (response.statusCode == 200) {
        Map<String, String> receivedData = Map<String, String>.from(json.decode(response.body));
        for (var patient in patients) {
          String mac = patient["rfid"] ?? "";
          if (receivedData.containsKey(mac)) {
            patient["status"] = (receivedData[mac] == "IN_RANGE") ? "IN_RANGE" : "OUT_OF_RANGE";
          } else {
            patient["status"] = "OUT_OF_RANGE";
          }
        }
        setState(() {}); // Refresh UI
      } else {
        print('Failed to fetch beacon data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching beacon data: $e');
    }
  }

  /// Shows a bottom sheet for changing the subscription plan.
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
                onChanged: (newValue) {
                  setState(() {
                    subscriptionPlan = newValue!;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Navigates to the detailed patient view.
  void _viewPatientDetails(Map<String, String> patient, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(
          patient: patient,
          patientIndex: index,
          onDelete: () {
            _deletePatient(index);
            Navigator.pop(context);
          },
          onEdit: () {
            Navigator.pop(context);
            _showAddOrEditPatientDialog(patient: patient, index: index);
          },
          onMemoryTestComplete: (String result) async {
            // Update patient's memory_test_result then store in local data.
            patient['memory_test_result'] = result;
            await _addOrUpdatePatient(patient, isEditing: true, index: index);
          },
        ),
      ),
    );
  }

  /// Shows a dialog for adding or editing a patient.
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Map<String, String> newPatient = {
                "name": nameController.text,
                "age": ageController.text,
                "height": heightController.text,
                "weight": weightController.text,
                "caregiver": caregiverController.text,
                "rfid": rfidController.text,
                "status": patient?['status'] ?? "Unknown",
                "memory_test_result": patient?['memory_test_result'] ?? "",
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

  /// Builds the main scaffold for the Caregiver Dashboard.
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
                  MaterialPageRoute(builder: (context) => SettingsScreen(onThemeChanged: widget.onThemeChanged, isDarkTheme: widget.isDarkTheme)),
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
                  MaterialPageRoute(builder: (_) => LoginScreen(onThemeChanged: widget.onThemeChanged, isDarkTheme: widget.isDarkTheme)),
                );
              },
            ),
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
            trailing: (patient["status"] == "IN_RANGE")
                ? Icon(Icons.check_circle, color: Colors.green)
                : (patient["status"] == "OUT_OF_RANGE")
                ? Icon(Icons.warning, color: Colors.red)
                : Icon(Icons.help, color: Colors.grey),
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

/// Updated PatientDetailsScreen as a StatefulWidget that auto-refreshes to show the latest memory test score.
class PatientDetailsScreen extends StatefulWidget {
  final Map<String, String> patient;
  final int patientIndex;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final ValueChanged<String> onMemoryTestComplete;

  PatientDetailsScreen({
    required this.patient,
    required this.patientIndex,
    required this.onDelete,
    required this.onEdit,
    required this.onMemoryTestComplete,
  });

  @override
  _PatientDetailsScreenState createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  late String memoryTestResult;

  @override
  void initState() {
    super.initState();
    memoryTestResult = widget.patient['memory_test_result'] ?? '';
  }

  void _updateMemoryTestResult(String result) {
    setState(() {
      memoryTestResult = result;
    });
    widget.patient['memory_test_result'] = result;
    widget.onMemoryTestComplete(result);
  }

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final oxygenSaturation = 95 + random.nextInt(6);
    final respiratoryRate = 12 + random.nextInt(9);
    return Scaffold(
      appBar: AppBar(
        title: Text("Patient Details"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "Delete") {
                widget.onDelete();
                Navigator.pop(context);
              } else if (value == "Edit") {
                widget.onEdit();
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name: ${widget.patient["name"]}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Age: ${widget.patient["age"]}"),
              Text("Height: ${widget.patient["height"]}"),
              Text("Weight: ${widget.patient["weight"]}"),
              Text("Caregiver Contact: ${widget.patient["caregiver"]}"),
              Text("RFID Mac Address: ${widget.patient["rfid"]}"),
              Text("Status: ${widget.patient["status"]}"),
              SizedBox(height: 20),
              Text("Heart Rate (BPM)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Container(
                height: 250,
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
                      getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(fontSize: 10)),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(fontSize: 10)),
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
                          FlSpot(0, 100),
                          FlSpot(1, 105),
                          FlSpot(2, 110),
                          FlSpot(3, 120),
                          FlSpot(4, 140),
                          FlSpot(5, 130),
                          FlSpot(6, 140),
                          FlSpot(7, 120),
                          FlSpot(8, 110),
                          FlSpot(9, 110),
                          FlSpot(10, 105),
                          FlSpot(11, 110),
                          FlSpot(12, 100),
                          FlSpot(13, 105),
                          FlSpot(14, 110),
                          FlSpot(15, 120),
                          FlSpot(16, 140),
                          FlSpot(17, 130),
                          FlSpot(18, 140),
                          FlSpot(19, 120),
                          FlSpot(20, 110),
                          FlSpot(21, 110),
                          FlSpot(22, 105),
                          FlSpot(23, 110),
                          FlSpot(24, 110),
                          FlSpot(25, 105),
                          FlSpot(26, 110),
                          FlSpot(27, 100),
                          FlSpot(28, 105),
                          FlSpot(29, 110),
                          FlSpot(30, 120),
                          FlSpot(31, 140),
                          FlSpot(32, 130),
                          FlSpot(33, 140),
                          FlSpot(34, 120),
                          FlSpot(35, 110),
                          FlSpot(36, 110),
                          FlSpot(37, 105),
                          FlSpot(38, 110),
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
              Text("Oxygen Saturation: $oxygenSaturation%", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("Respiratory Rate: $respiratoryRate breaths/min", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              if (memoryTestResult.isNotEmpty) ...[
                Text("Latest Memory Test Result:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(memoryTestResult),
                SizedBox(height: 20),
              ],
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemoryTestScreen(
                        onTestComplete: (String finalResult) {
                          Navigator.pop(context, finalResult);
                        },
                      ),
                    ),
                  );
                  if (result != null) {
                    _updateMemoryTestResult(result);
                  }
                },
                child: Text("Take Memory Test"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
