import 'dart:convert';
import 'package:boxing_camp_app/main.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = '$apiUrl/getcamp';
  final String editCampUrl =
      '$apiUrl/editcamp'; // Endpoint for editing
  final String deleteCampUrl =
      '$apiUrl/deletecamp'; // Endpoint for deleting

  Future<void> editCamp(String id, Map<String, dynamic> campData) async {
    final response = await http.put(
      Uri.parse('$editCampUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(campData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to edit camp');
    }
  }

  Future<void> deleteCamp(String id) async {
    final response = await http.delete(Uri.parse('$deleteCampUrl/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete camp');
    }
  }
}

class EditCampPage extends StatefulWidget {
  final String? username;
  final String id;

  const EditCampPage({super.key, this.username, required this.id});

  @override
  _EditCampPageState createState() => _EditCampPageState();
}

class _EditCampPageState extends State<EditCampPage> {
  late String name;
  late String description;
  late double latitude;
  late double longitude;
  // late String imageUrl;
  bool isLoading = true;

  String accessToken = "";
  String refreshToken = "";
  String role = "";
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;
  String? username;
  List<dynamic> allCamps = [];

  ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    getInitialize();
    _fetchCamp();
  }

  Future<void> _fetchCamp() async {
    try {
      final response =
          await http.get(Uri.parse('$apiUrl/getcamp'));
      if (response.statusCode == 200) {
        // Convert JSON data to List
        final List<dynamic> camps = jsonDecode(response.body);
        print(response.body);

        // Update state with all camp data
        setState(() {
          allCamps = camps; // Store all camp data in allCamps variable
        });
      } else {
        throw Exception('Failed to load camp data');
      }
    } catch (error) {
      print('Error fetching camp: $error');
    }
  }

  Future<Map<String, dynamic>> _fetchCurrentCamp(String id) async {
    final response = await http.get(Uri.parse('$apiUrl/getcamp'));

    if (response.statusCode == 200) {
      // สมมติว่า response.body เป็น List<dynamic>
      final List<dynamic> camps = jsonDecode(response.body);

      // หาค่ายที่ตรงกับ ID
      final camp =
          camps.firstWhere((camp) => camp['_id'] == id, orElse: () => null);

      if (camp != null) {
        return camp; // ส่งกลับข้อมูลค่ายในรูปแบบ Map
      } else {
        throw Exception('Camp not found');
      }
    } else {
      throw Exception('Failed to load current camp data');
    }
  }

  Future<void> _editCamp(String id) async {
    // Fetch current camp data (You may need to implement a method to get this)
    final currentCamp = await _fetchCurrentCamp(id); // Implement this method

    final campData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        String name = currentCamp['name'] ?? '';
        String description = currentCamp['description'] ?? '';
        double latitude = currentCamp['location']['latitude'] ?? 0.0;
        double longitude = currentCamp['location']['longitude'] ?? 0.0;

        TextEditingController nameController =
            TextEditingController(text: name);
        TextEditingController descriptionController =
            TextEditingController(text: description);
        TextEditingController latitudeController =
            TextEditingController(text: latitude.toString());
        TextEditingController longitudeController =
            TextEditingController(text: longitude.toString());

        return AlertDialog(
          title: Text('จัดการค่าย'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'ชื่อค่าย'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'คำอธิบายค่าย'),
              ),
              TextField(
                controller: latitudeController,
                decoration: InputDecoration(labelText: 'ละติจูด'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: longitudeController,
                decoration: InputDecoration(labelText: 'ลองติจูด'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancel
              },
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'name': nameController.text,
                  'description': descriptionController.text,
                  'location': {
                    'latitude': double.tryParse(latitudeController.text) ?? 0.0,
                    'longitude':
                        double.tryParse(longitudeController.text) ?? 0.0,
                  },
                });
              },
              child: Text('บันทึก'),
            ),
          ],
        );
      },
    );

    // If user entered data, update
    if (campData != null) {
      try {
        await apiService.editCamp(id, campData);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('อัพเดทเสร็จสมบูรณ์!'),
        ));
        _fetchCamp(); // Refresh camp data
      } catch (error) {
        print('Error updating camp: $error');
      }
    }
  }

  Future<void> _deleteCamp(String id) async {
    try {
      await apiService.deleteCamp(id);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('ลบข้อมูลเสร็จเรียบร้อย!')));
      _fetchCamp(); // Refresh camp data after deletion
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete camp: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'จัดการค่าย',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        elevation: 10,
        backgroundColor: const Color.fromARGB(248, 226, 131, 53),
        actions: [
          if (username != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  '$username',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(width: 16),
        ],
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
      body: allCamps.isEmpty
          ? Center(
              child: CircularProgressIndicator()) // Show loading if no data yet
          : ListView.builder(
              itemCount: allCamps.length,
              itemBuilder: (context, index) {
                final camp = allCamps[index];
                return ListTile(
                  title: Text(camp['name'] ?? 'No Name'),
                  subtitle: Text(camp['description'] ?? 'No Description'),
                  onTap: () {
                    // Show AlertDialog for action selection
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('เลือกการดำเนินการ'),
                          content: Text('คุณต้องการจะแก้ไขหรือลบค่ายนี้?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                // If edit is selected, call edit function
                                _editCamp(camp['_id']); // Call edit function
                                // Navigator.of(context)
                                //     .pop(); // Close AlertDialog
                              },
                              child: Text('แก้ไข'),
                            ),
                            TextButton(
                              onPressed: () {
                                // If delete is selected, call delete function
                                _deleteCamp(
                                    camp['_id']); // Call delete function
                                Navigator.of(context)
                                    .pop(); // Close AlertDialog
                              },
                              child: Text('ลบ'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .pop(); // Close AlertDialog
                              },
                              child: Text('ยกเลิก'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/addCamp');
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn") ?? false;
      username = prefs.getString("username");
      accessToken = prefs.getString("accessToken") ?? "";
      refreshToken = prefs.getString("refreshToken") ?? "";
      role = prefs.getString("role") ?? "";
    });
  }
}
