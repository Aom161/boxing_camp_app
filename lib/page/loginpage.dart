import 'dart:convert';
import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'registerpage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$apiUrl/login');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        'username': _usernameController.text,
        'password': _passwordController.text
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final accessToken = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];
        String role = responseData['users']['role'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('accessToken', accessToken);
        prefs.setString('refreshToken', refreshToken);
        prefs.setString('_id', responseData['users']['_id']);
        prefs.setString('username', responseData['users']['username']);
        prefs.setBool('isLoggedIn', true);
        prefs.setString('role', role);

        print(prefs.getString("accessToken"));

        _showSnackBar("เข้าสู่ระบบสำเร็จ", Colors.green);

        _checkLogin(role);
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง';
        });
        _showSnackBar(_errorMessage!, Colors.red);
      } else {
        setState(() {
          _errorMessage = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ กรุณาลองใหม่อีกครั้ง';
        });
        _showSnackBar(_errorMessage!, Colors.red);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ข้อผิดพลาดทางเครือข่าย: $e';
      });
      _showSnackBar(_errorMessage!, Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkLogin(String role) {
    if (role == 'ผู้ดูแลระบบ') {
      Navigator.pushReplacementNamed(context, '/adminpage');
    } else if (role == 'ผู้จัดการค่ายมวย') {
      Navigator.pushReplacementNamed(context, '/managerpage');
    } else if (role == 'ครูมวย') {
      Navigator.pushReplacementNamed(context, '/trainer');
    } else if (role == 'นักมวย') {
      Navigator.pushReplacementNamed(context, '/boxerpage');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    final snackbar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      backgroundColor: backgroundColor,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'เข้าสู่ระบบ',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color.fromARGB(248, 226, 131, 53),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logomuay.png',
                width: 450,
                height: 350,
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 10),
                        ],
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณาใส่ชื่อผู้ใช้';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณาใส่รหัสผ่าน';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _login,
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
                                  'เข้าสู่ระบบ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RegisterScreen()),
                            );
                          },
                          child: const Text('คุณไม่มีบัญชีใช่หรือไม่? สมัครสมาชิก'),
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
