import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class EditProfile extends StatefulWidget {
  final String? username;
  final Map<String, dynamic> userData;

  const EditProfile({super.key, required this.userData, this.username});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late String? _id;
  late String? username;
  String accessToken = "";
  String refreshToken = "";
  String role = "";
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;
  late TextEditingController _fullnameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _telephoneController;

  @override
  void initState() {
    super.initState();
    getInitialize();
    _fullnameController =
        TextEditingController(text: widget.userData['fullname']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _addressController =
        TextEditingController(text: widget.userData['address']);
    _telephoneController =
        TextEditingController(text: widget.userData['telephone']);
  }

  void getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn")!;
      username = prefs.getString("username");
      accessToken = prefs.getString("accessToken")!;
      refreshToken = prefs.getString("refreshToken")!;
      role = prefs.getString("role")!;
      _id = prefs.getString('_id');
    });

    print(_isCheckingStatus);
    print(username);
    print(accessToken);
    print(refreshToken);
    print(role);
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // Validate input fields
    if (_fullnameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _telephoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return; // Exit if validation fails
    }

    final updatedData = {
      'fullname': _fullnameController.text,
      'email': _emailController.text,
      'username': username, // Add the username here
      'address': _addressController.text,
      'telephone': _telephoneController.text,
    };

    print('Updating user with ID: $_id');
    print('Updated Data: $updatedData');

    final response = await http.put(
      Uri.parse('$apiUrl/updateProfile/$_id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updatedData),
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      print('Error: ${response.statusCode}, Message: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'แก้ไขโปรไฟล์',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
        backgroundColor: const Color.fromARGB(248, 226, 131, 53),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _fullnameController,
              decoration: const InputDecoration(labelText: 'แก้ไขชื่อ'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'แก้ไขอีเมล'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'แก้ไขที่อยู่'),
            ),
            TextField(
              controller: _telephoneController,
              decoration: const InputDecoration(labelText: 'แก้ไขเบอร์โทร'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }
}
