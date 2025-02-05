class Patient {
  final String id;
  final String name;
  final bool inRange; // Whether the patient is in range or not
  final String lastSeen;

  Patient({required this.id, required this.name, required this.inRange, required this.lastSeen});
}
