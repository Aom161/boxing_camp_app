import 'package:boxing_camp_app/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminHomePage extends StatefulWidget {
  final String? username;
  const AdminHomePage({super.key, this.username});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late String? username;
  String accessToken = "";
  String refreshToken = "";
  String role = "";
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
      _isCheckingStatus = prefs.getBool("isLoggedIn")!;
      username = prefs.getString("username");
      accessToken = prefs.getString("accessToken")!;
      refreshToken = prefs.getString("refreshToken")!;
      role = prefs.getString("role")!;
    });

    print(_isCheckingStatus);
    print(username);
    print(accessToken);
    print(refreshToken);
    print(role);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "AdminHomePage",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        elevation: 10,
        backgroundColor: const Color.fromARGB(248, 226, 131, 53),
        actions: [
          if (username != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  'ยินดีต้อนรับคุณ $username',
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
      body: const Column(
        children: [],
      ),
    );
  }
}
