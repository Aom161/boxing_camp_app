import 'dart:convert';
import 'package:boxing_camp_app/page/loginpage.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  String _email = '';
  String _fullname = '';
  String _address = '';
  String _phoneNumber = '';
  String? _selectedRole;
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "fullname": _fullname,
          "username": _username,
          "email": _email,
          "password": _password,
          "address": _address,
          "telephone": _phoneNumber,
          "role": _selectedRole,
        }),
      );

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('สมัครสมาชิกสำเร็จ'),
              content: const Text('คุณได้สมัครสมาชิกเรียบร้อยแล้ว'),
              actions: [
                TextButton(
                  child: const Text('ตกลง'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                ),
              ],
            );
          },
        );
      } else {
        final responseData = json.decode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ??
              'Registration failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'สมัครสมาชิก',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color.fromARGB(248, 226, 131, 53),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logomuay.png',
                width: 250,
                height: 250,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 10),
                        ],
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'ชื่อผู้ใช้'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณาใส่ชื่อผู้ใช้';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _username = value!;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'รหัสผ่าน'),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณาใส่รหัสผ่าน';
                            } else if (value.length < 8) {
                              return 'รหัสผ่านต้องมีความยาวขั้นต่ำ 8 ตัวอักษร';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _password = value!;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'ชื่อ-นามสกุล'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณาใส่ชื่อ-นามสกุล';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _fullname = value!;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'อีเมล'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                !RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(value)) {
                              return 'กรุณาใส่อีเมล';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _email = value!;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'ที่อยู่'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณาใส่ที่อยู่';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _address = value!;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'เบอร์โทร'),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            final phoneRegExp = RegExp(r'^0[0-9]{9}$');
                            if (value == null || !phoneRegExp.hasMatch(value)) {
                              return "เบอร์ไม่ถูกต้อง";
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _phoneNumber = value!;
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          decoration:
                              const InputDecoration(labelText: 'ตำแหน่ง'),
                          value: _selectedRole,
                          items: ['ครูมวย', 'นักมวย', 'ผู้จัดการค่ายมวย']
                              .map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'กรุณาเลือกตำแหน่ง';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                const Color.fromARGB(255, 214, 115, 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 30),
                            elevation: 5,
                          ),
                          child: const Text(
                            'สมัครสมาชิก',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
