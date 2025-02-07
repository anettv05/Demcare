import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LogsScreen extends StatefulWidget {
  @override
  _LogsScreenState createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  Map<String, String> beaconStatus = {}; // Store beacon data
  String serverIp = "192.168.1.100"; // Replace with your Raspberry Pi's IP

  Future<void> fetchBeaconStatus() async {
    try {
      final response = await http.get(Uri.parse('http://$serverIp:5000/get_status'));

      if (response.statusCode == 200) {
        setState(() {
          beaconStatus = Map<String, String>.from(json.decode(response.body));
        });
      } else {
        print('Failed to fetch beacon data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchBeaconStatus(); // Fetch beacon data when the screen loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Logs'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchBeaconStatus, // Refresh button
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
                title: Text('Beacon ${entry.key}'),
                subtitle: Text('Status: ${entry.value}'),
                leading: Icon(
                  entry.value == "IN_RANGE" ? Icons.check_circle : Icons.warning,
                  color: entry.value == "IN_RANGE" ? Colors.green : Colors.red,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
