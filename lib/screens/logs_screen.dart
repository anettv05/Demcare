import 'package:flutter/material.dart';

class LogsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Logs")),
      body: Center(child: Text("Log Records")),
    );
  }
}
