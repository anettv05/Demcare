import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveFeedScreen extends StatefulWidget {
  @override
  _LiveFeedScreenState createState() => _LiveFeedScreenState();
}

class _LiveFeedScreenState extends State<LiveFeedScreen> {
  VlcPlayerController? _vlcViewController;
  TextEditingController _macAddressController = TextEditingController();
  String _streamUrl = "";
  String _loggedInUser = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _loggedInUser = prefs.getString('loggedInUser') ?? "";
    String? savedMac = prefs.getString('user_${_loggedInUser}_mac');
    if (savedMac != null) {
      _macAddressController.text = savedMac;
      _setStreamUrl(savedMac);
    }
  }

  void _setStreamUrl(String macAddress) {
    setState(() {
      _streamUrl = 'rtsp://$macAddress:8554/live';
      _vlcViewController = VlcPlayerController.network(
        _streamUrl,
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(),
      );
    });
  }

  Future<void> _saveMacAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String macAddress = _macAddressController.text.trim();
    await prefs.setString('user_${_loggedInUser}_mac', macAddress);
    _setStreamUrl(macAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Camera Feed")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _macAddressController,
                    decoration: InputDecoration(
                      labelText: "Enter Raspberry Pi IP Address",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _saveMacAddress,
                  child: Text("Save"),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: _vlcViewController == null
                  ? Text("Enter a IP address to start streaming")
                  : VlcPlayer(
                controller: _vlcViewController!,
                aspectRatio: 16 / 9,
                placeholder: Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}