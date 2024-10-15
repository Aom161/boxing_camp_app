import 'dart:convert';
import 'package:boxing_camp_app/main.dart';
import 'package:boxing_camp_app/page/boxertrainingpage.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardManagerPage extends StatefulWidget {
  final String? username;
  const DashboardManagerPage({super.key, this.username});

  @override
  State<DashboardManagerPage> createState() => _DashboardManagerPageState();
}

class _DashboardManagerPageState extends State<DashboardManagerPage> {
  late String? username;
  late String? _id;
  String accessToken = "";
  String refreshToken = "";
  String role = "";
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;
  late String campName;
  List<String> approvedBoxerNames = [];
  List<String> approvedBoxerIds = [];

  @override
  void initState() {
    super.initState();
    username = widget.username;
    getInitialize();
    _fetchCampAndTrainingData();
  }

  void getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn") ?? false;
      username = prefs.getString("username") ?? "ไม่ได้ลงชื่อเข้าใช้";
      accessToken = prefs.getString("accessToken") ?? "";
      refreshToken = prefs.getString("refreshToken") ?? "";
      role = prefs.getString("role") ?? "No Role";
      _id = prefs.getString('_id');
    });
  }

  Future<void> _fetchCampAndTrainingData() async {
    try {
      final requestResponse = await http.get(
        Uri.parse('$apiUrl/getallrequest'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (requestResponse.statusCode == 200) {
        final requestData = jsonDecode(requestResponse.body);
        if (requestData is List) {
          for (var request in requestData) {
            String managerIdString = request['managerId']['_id'] ?? '';
            String boxerIdString = request['boxerId']['_id'] ?? '';
            String boxerNameString = request['boxerId']['fullname'] ?? '';
            String status = request['status']?.toString() ?? '';

            if (managerIdString == _id && status == 'approved') {
              setState(() {
                approvedBoxerIds.add(boxerIdString);
                approvedBoxerNames.add(boxerNameString);
              });
            }
          }

          if (approvedBoxerIds.isEmpty) {
            setState(() {
              campName = 'ยังไม่มีนักมวยที่ได้รับการอนุมัติ';
            });
          }
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "แดชบอร์ด",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
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
      body: approvedBoxerNames.isEmpty
          ? Center(child: Text('ยังไม่มีนักมวยที่ได้รับการอนุมัติ'))
          : ListView.builder(
              itemCount: approvedBoxerNames.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(approvedBoxerNames[index]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BoxerTrainingPage(
                          boxerId: approvedBoxerIds[index],
                          boxerName: approvedBoxerNames[index],
                          accessToken: accessToken,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
