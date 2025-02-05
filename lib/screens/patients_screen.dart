import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PatientsScreen extends StatefulWidget {
  @override
  _PatientsScreenState createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Patients List")),
      body: patients.isEmpty
          ? Center(child: Text("No patients added yet"))
          : ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          var patient = patients[index];
          return ListTile(
            title: Text(patient["name"] ?? "Unknown"),
            subtitle: Text("RFID: ${patient["rfid"]}"),
            trailing: Icon(Icons.arrow_forward_ios),
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
          ],
        ),
      ),
    );
  }
}
