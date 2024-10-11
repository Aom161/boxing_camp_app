import 'dart:convert';
import 'package:boxing_camp_app/main.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RequestToJoinCampPageForTrainers extends StatefulWidget {
  final String? username;

  const RequestToJoinCampPageForTrainers({super.key, this.username});

  @override
  _RequestToJoinCampPageForTrainersState createState() =>
      _RequestToJoinCampPageForTrainersState();
}

class _RequestToJoinCampPageForTrainersState
    extends State<RequestToJoinCampPageForTrainers> {
  String? selectedCampId;
  List<dynamic> camps = [];
  String accessToken = "";
  String refreshToken = "";
  String role = "";
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;
  String? username;
  String? _id;

  @override
  void initState() {
    super.initState();
    fetchCamps(); // Fetch camps when the page loads
    username = widget.username;
    getInitialize();
  }

  void getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn") ?? false;
      username = prefs.getString("username") ?? "";
      accessToken = prefs.getString("accessToken") ?? "";
      refreshToken = prefs.getString("refreshToken") ?? "";
      role = prefs.getString("role") ?? "";
      _id = prefs.getString('_id') ?? "";
    });

    print(_isCheckingStatus);
    print(username);
    print(accessToken);
    print(refreshToken);
    print(role);
  }

  Future<void> fetchCamps() async {
    final response = await http.get(
      Uri.parse('$apiUrl/getcamp'),
    );

    print(response.body);

    if (response.statusCode == 200) {
      setState(() {
        camps = jsonDecode(response.body); // Set camps for dropdown
      });
    } else {
      throw Exception('Failed to load camps');
    }
  }

  Future<void> submitRequest(String _id, String campId) async {
    // Ensure the access token is not empty or null
    if (accessToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access token is missing!')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('$apiUrl/trainerrequest'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken', // Include the access token
      },
      body: jsonEncode({
        'trainerId': _id,
        'campId': campId
      }), // Using 'trainerId' instead of 'boxerId'
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request submitted successfully!')),
      );
    } else if (response.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unauthorized: Invalid access token.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set trainerId from stored _id if it's available
    String trainerId = _id ?? ''; // Ensure it's not null

    return Scaffold(
      appBar: AppBar(
        title: Text('Request to Join Camp (Trainer)'),
      ),
      drawer: BaseAppDrawer(
        username: username,
        isLoggedIn: _isCheckingStatus,
        role: role,
        onHomeTap: (context) {
          Navigator.pushNamed(context, '/home');
        },
        onCampTap: (context) {
          Navigator.pushNamed(context, '/dashboard');
        },
        onContactTap: (context) {
          Navigator.pushNamed(context, '/contact');
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a Camp to Join:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            camps.isEmpty
                ? Center(child: CircularProgressIndicator())
                : DropdownButton<String>(
                    value: selectedCampId,
                    isExpanded: true,
                    hint: Text('Choose a Camp'),
                    items: camps.map<DropdownMenuItem<String>>((camp) {
                      return DropdownMenuItem<String>(
                        value: camp['_id'] ?? '',
                        child: Text(camp['name'] ?? 'Unknown Camp'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCampId = value; // Update the selected camp ID
                      });
                    },
                  ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: selectedCampId == null || selectedCampId!.isEmpty
                  ? null // Disable the button if no camp is selected
                  : () {
                      submitRequest(
                          trainerId, selectedCampId!); // Use the selectedCampId
                    },
              child: Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}
