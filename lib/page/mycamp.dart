import 'package:boxing_camp_app/main.dart';
import 'package:boxing_camp_app/page/campdetail.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MyCampsScreen extends StatefulWidget {
  final String? username;
  final String manager;

  const MyCampsScreen({super.key, required this.manager, this.username});

  @override
  _MyCampsScreenState createState() => _MyCampsScreenState();
}

class _MyCampsScreenState extends State<MyCampsScreen> {
  List<dynamic> mycamps = [];
  bool isLoading = true;
  late String? username;
  late String managerId;
  String accessToken = "";
  String refreshToken = "";
  String role = "";
  late String? _id;
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    username = widget.username;
    managerId = widget.manager;
    getInitialize();
    fetchCamps();
  }

  void getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn")!;
      username = prefs.getString("username");
      accessToken = prefs.getString("accessToken")!;
      refreshToken = prefs.getString("refreshToken")!;
      role = prefs.getString("role")!;
      _id = prefs.getString('_id')!;
    });

    print(_isCheckingStatus);
    print(_id);
    print(username);
    print(accessToken);
    print(refreshToken);
    print(role);
  }

  Future<void> fetchCamps() async {
    final response = await http.get(Uri.parse('$apiUrl/getcamp'));

    if (response.statusCode == 200) {
      List<dynamic> allCamps = json.decode(response.body);
      setState(() {
        mycamps = allCamps
            .where((camps) => camps['manager'] == _id)
            .toList();
        isLoading = false;
      });
      if (mycamps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบค่ายมวยที่คุณจัดการ')),
        );
      }
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถโหลดข้อมูลค่ายมวย')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ค่ายมวยของคุณ'),
        backgroundColor: const Color.fromARGB(248, 226, 131, 53),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : mycamps.isEmpty
              ? const Center(child: Text('ไม่มีค่ายมวยที่แสดง'))
              : ListView.builder(
                  itemCount: mycamps.length,
                  itemBuilder: (context, index) {
                    final camp = mycamps[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(camp['name']),
                        subtitle: Text(camp['description'] ?? 'ไม่มีคำอธิบาย'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CampDetailScreen(camp: camp),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
