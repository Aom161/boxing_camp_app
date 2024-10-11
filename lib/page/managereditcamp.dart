import 'dart:convert';
import 'package:boxing_camp_app/main.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = '$apiUrl/getcamp';
  final String editCampUrl = '$apiUrl/editcamp';
  final String deleteCampUrl = '$apiUrl/deletecamp';

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

class ManagerEditCampPage extends StatefulWidget {
  final String? username;

  const ManagerEditCampPage({super.key, this.username});

  @override
  _ManagerEditCampPageState createState() => _ManagerEditCampPageState();
}

class _ManagerEditCampPageState extends State<ManagerEditCampPage> {
  late String? username;
  late String accessToken;
  late String role;
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;
  List<dynamic> allCamps = [];
  String managerId = '';

  ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    getInitialize();
    _fetchCamps();
  }

  Future<void> _fetchCamps() async {
    try {
      final response = await http.get(Uri.parse(apiService.baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> camps = jsonDecode(response.body);
        setState(() {
          allCamps =
              camps.where((camp) => camp['manager'] == managerId).toList();
        });
      } else {
        throw Exception('Failed to load camp data');
      }
    } catch (error) {
      print('Error fetching camps: $error');
    }
  }

  Future<void> getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn") ?? false;
      username = prefs.getString("username");
      accessToken = prefs.getString("accessToken") ?? "";
      role = prefs.getString("role") ?? "";
      managerId = prefs.getString('_id') ?? ''; // Get the manager ID
    });
  }

  Future<void> _editCamp(String id) async {
    final currentCamp = allCamps.firstWhere((camp) => camp['_id'] == id);
    final campData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        TextEditingController nameController =
            TextEditingController(text: currentCamp['name'] ?? '');
        TextEditingController descriptionController =
            TextEditingController(text: currentCamp['description'] ?? '');

        return AlertDialog(
          title: Text('แก้ไขค่าย'),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null), // Cancel
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'name': nameController.text,
                  'description': descriptionController.text,
                });
              },
              child: Text('บันทึก'),
            ),
          ],
        );
      },
    );

    if (campData != null) {
      try {
        await apiService.editCamp(id, campData);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('อัพเดทเสร็จสมบูรณ์!')));
        _fetchCamps(); // Refresh camp data
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
      _fetchCamps(); // Refresh camp data after deletion
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
      ),
      body: allCamps.isEmpty
          ? const Center(child: CircularProgressIndicator())
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
                                _editCamp(camp['_id']); // Call edit function
                              },
                              child: Text('แก้ไข'),
                            ),
                            TextButton(
                              onPressed: () {
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
    );
  }
}
