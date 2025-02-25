import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Import Timer for auto-refresh

class LogsScreen extends StatefulWidget {
  @override
  _LogsScreenState createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  Map<String, String> beaconStatus = {}; // Stores received beacons data
  List<Map<String, String>> patients = []; // List of stored patients
  String serverIp = "192.168.61.162"; // Replace with your Raspberry Pi's IP
  Timer? _timer; // Timer for auto-refresh

  @override
  void initState() {
    super.initState();
    _loadPatients();
    fetchBeaconStatus(); // Fetch beacon data when the screen loads

    // Start auto-refresh every 1 second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      fetchBeaconStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop auto-refresh when the screen is closed
    super.dispose();
  }

  /// Loads saved patient data from SharedPreferences
  Future<void> _loadPatients() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String loggedInUser = prefs.getString('loggedInUser') ?? '';
    List<String> storedPatients = prefs.getStringList('patients_$loggedInUser') ?? [];

    setState(() {
      patients = storedPatients.map((patientJson) {
        return Map<String, String>.from(json.decode(patientJson));
      }).toList();
    });
  }

  /// Fetches beacon data from Raspberry Pi and updates UI
  Future<void> fetchBeaconStatus() async {
    try {
      final response = await http.get(Uri.parse('http://$serverIp:5000/get_status'));

      if (response.statusCode == 200) {
        Map<String, String> receivedData = Map<String, String>.from(json.decode(response.body));
        Map<String, String> updatedStatus = {};

        // Check each patient in the stored patient list
        for (var patient in patients) {
          String mac = patient["rfid"] ?? ""; // Get RFID MAC address
          String name = patient["name"] ?? "Unknown";

          if (receivedData.containsKey(mac)) {
            updatedStatus[name] = receivedData[mac] == "IN_RANGE" ? "IN_RANGE" : "OUT_OF_RANGE";
          } else {
            updatedStatus[name] = "OUT_OF_RANGE"; // Default if no data received
          }
        }

        // Handle unknown beacons (beacons not linked to any patient)
        receivedData.forEach((mac, status) {
          // Check if this MAC matches a patient RFID
          String? matchedPatient = patients.firstWhere(
                (patient) => patient["rfid"] == mac,
            orElse: () => {"name": "Unknown Device ($mac)"},
          )["name"];

          updatedStatus[matchedPatient!] = status;
        });

        // Update the UI
        setState(() {
          beaconStatus = updatedStatus;
        });
      } else {
        print('Failed to fetch beacon data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Logs'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchBeaconStatus, // Manual refresh button
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchBeaconStatus,
        child: ListView(
          children: beaconStatus.entries.map((entry) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: ListTile(
                title: Text(entry.key), // Displays patient name or "Unknown Device"
                subtitle: Text('Status: ${entry.value}'),
                leading: Icon(
                  entry.value == "IN_RANGE"
                      ? Icons.check_circle
                      : entry.value == "UNKNOWN"
                      ? Icons.help_outline
                      : Icons.warning,
                  color: entry.value == "IN_RANGE"
                      ? Colors.green
                      : entry.value == "UNKNOWN"
                      ? Colors.grey
                      : Colors.red,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
