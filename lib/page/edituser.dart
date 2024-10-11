import 'dart:convert';
import 'package:boxing_camp_app/models/user.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class EditUserScreen extends StatefulWidget {
  final User user;

  const EditUserScreen({super.key, required this.user});

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullnameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _addressController;
  late TextEditingController _telephoneController;
  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    _fullnameController = TextEditingController(text: widget.user.fullname);
    _emailController = TextEditingController(text: widget.user.email);
    _usernameController = TextEditingController(text: widget.user.username);
    _addressController = TextEditingController(text: widget.user.address);
    _telephoneController = TextEditingController(text: widget.user.telephone);
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _addressController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form is not valid
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final response = await http.put(
        Uri.parse('$apiUrl/updateuser/${widget.user.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        },
        body: json.encode({
          'fullname': _fullnameController.text,
          'email': _emailController.text,
          'username': _usernameController.text,
          'address': _addressController.text,
          'telephone': _telephoneController.text,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัปเดตข้อมูลสำเร็จ'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Display error message
        final errorMessage =
            json.decode(response.body)['message'] ?? 'ไม่สามารถอัปเดตผู้ใช้ได้';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Catch any other errors
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถอัปเดตผู้ใช้ได้'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขผู้ใช้'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'ID: ${widget.user.id}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _fullnameController,
                decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่อ-นามสกุล';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'อีเมล'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกอีเมล';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่อผู้ใช้';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'ที่อยู่'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกที่อยู่';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(labelText: 'เบอร์โทรศัพท์'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกเบอร์โทรศัพท์';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _updateUser, // Disable button during loading
                child: _isLoading
                    ? const CircularProgressIndicator() // Show loading spinner
                    : const Text('อัปเดต'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
