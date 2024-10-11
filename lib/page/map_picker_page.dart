import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapPickerPage extends StatefulWidget {
  final String? username;

  const MapPickerPage({super.key, this.username});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  String? username;
  String latitude = '';
  String longitude = '';
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    username = widget.username;
    getInitialize();
  }

  void getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn") ?? false;
      username = prefs.getString("username");
    });
  }

  void _confirmSelection() {
    if (latitude.isNotEmpty && longitude.isNotEmpty) {
      try {
        double lat = double.parse(latitude);
        double lng = double.parse(longitude);
        Navigator.pop(context, LatLng(lat, lng));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('กรุณากรอกค่าละติจูดและลองติจูดที่ถูกต้อง')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกละติจูดและลองติจูด')),
      );
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ยืนยันการออก'),
            content:
                const Text('คุณแน่ใจว่าต้องการออกโดยไม่เลือกตำแหน่งหรือไม่?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('ไม่'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('ใช่'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'เลือกตำแหน่ง',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          elevation: 10,
          backgroundColor: const Color.fromARGB(248, 158, 25, 1),
          actions: [
            if (username != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    '$username',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 16),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'กรุณากรอกละติจูด',
                ),
                onChanged: (value) {
                  latitude = value;
                },
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'กรุณากรอกลองติจูด',
                ),
                onChanged: (value) {
                  longitude = value;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _confirmSelection,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('ยืนยันตำแหน่ง'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
