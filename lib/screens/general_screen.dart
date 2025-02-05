import 'package:flutter/material.dart';

class GeneralScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("General Info")),
      body: Center(child: Text("Patient Logs and Status")),
    );
  }
}
