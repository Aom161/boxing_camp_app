import 'package:boxing_camp_app/page/appprovedboxer.dart';
import 'package:boxing_camp_app/page/appprovedtrainer.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CampDetailScreen extends StatefulWidget {
  final String? username;
  final Map<String, dynamic> camp;

  const CampDetailScreen({super.key, required this.camp, this.username});

  @override
  _CampDetailScreenState createState() => _CampDetailScreenState();
}

class _CampDetailScreenState extends State<CampDetailScreen> {
  Map<String, dynamic>? manager;
  bool isLoading = true;
  late String? username;
  String accessToken = "";
  String refreshToken = "";
  String role = "";
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting("th_TH");
    username = widget.username;
    getInitialize();
    fetchManagerData();
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

  Future<void> fetchManagerData() async {
    final managerId = widget.camp['manager'];
    if (managerId != null) {
      final response = await http
          .get(Uri.parse('$apiUrl/getUserById/$managerId'));

      if (response.statusCode == 200) {
        var decodedResponse = json.decode(response.body);
        if (decodedResponse is List && decodedResponse.isNotEmpty) {
          setState(() {
            manager = decodedResponse[0].cast<String, dynamic>();
            isLoading = false;
          });
        } else if (decodedResponse is Map) {
          setState(() {
            manager = decodedResponse.cast<String, dynamic>();
            isLoading = false;
          });
        }
      } else {
        print('ไม่สามารถโหลดข้อมูลผู้จัดการ');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.camp['name']),
        backgroundColor: const Color.fromARGB(248, 226, 131, 53),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(
                              widget.camp['imageUrl'] ??
                                  'https://via.placeholder.com/800x200',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        left: MediaQuery.of(context).size.width * 0.5 - 50,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: NetworkImage(
                            widget.camp['imageUrl'] ??
                                'https://via.placeholder.com/150',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            widget.camp['name'],
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            widget.camp['description'] ?? 'ไม่มีคำอธิบาย',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const Text(
                          'ตำแหน่งที่ตั้ง:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ละติจูด: ${widget.camp['location']['latitude']}',
                          style: const TextStyle(
                              fontSize: 18, color: Colors.black87),
                        ),
                        Text(
                          'ลองจิจูด: ${widget.camp['location']['longitude']}',
                          style: const TextStyle(
                              fontSize: 18, color: Colors.black87),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        Text(
                          'อัปเดตเมื่อ: ${DateFormat.yMMMMd("th_TH").format(DateTime.parse(widget.camp['updated_at']))}',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[700]),
                        ),

                        // Text(
                        //   'อัปเดตเมื่อ: ${widget.camp['updated_at']}',
                        //   style:
                        //       TextStyle(fontSize: 18, color: Colors.grey[700]),
                        // ),

                        const SizedBox(height: 20),

                        _buildCustomBox('นักมวย', const Color(0xFFFED673),
                            context, widget.camp),
                        const SizedBox(height: 20),
                        _buildCustomBox('ครูมวย', const Color(0xFFFED673),
                            context, widget.camp),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  Text(
                    'ผู้จัดการ: ${manager?['fullname'] ?? 'ไม่มีผู้จัดการ'}',
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                ],
              ),
            ),
    );
  }
}

Future<List<dynamic>> fetchApprovedBoxers(Map<String, dynamic> camp) async {
  final campId = camp['_id']; // ใช้ campId ที่คุณต้องการ
  final response = await http
      .get(Uri.parse('$apiUrl/getApprovedBoxers/$campId'));

  if (response.statusCode == 200) {
    return json.decode(response.body); // คืนค่าข้อมูลนักมวยที่ได้รับการอนุมัติ
  } else {
    throw Exception('Failed to load approved boxers');
  }
}

Future<List<dynamic>> fetchApprovedTrainers(Map<String, dynamic> camp) async {
  final campId = camp['_id']; // Use the campId you want
  final response = await http
      .get(Uri.parse('$apiUrl/getApprovedTrainers/$campId'));

  if (response.statusCode == 200) {
    return json.decode(response.body); // Return the list of approved trainers
  } else {
    throw Exception('Failed to load approved trainers');
  }
}


Widget _buildCustomBox(String title, Color boxColor, BuildContext context,
    Map<String, dynamic> camp) {
  return GestureDetector(
    onTap: () async {
      if (title == 'นักมวย') {
        try {
          List<dynamic> approvedBoxers = await fetchApprovedBoxers(camp);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApprovedBoxersScreen(campId: camp['_id']),
            ),
          );
        } catch (e) {
          print('Error loading approved boxers: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('ไม่สามารถโหลดนักมวยที่ได้รับการอนุมัติได้')),
          );
        }
      } else if (title == 'ครูมวย') {
        try {
          List<dynamic> approvedTrainers = await fetchApprovedTrainers(camp);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApprovedTrainersScreen(
                  campId: camp[
                      '_id']), // You can create this screen similarly to `ApprovedBoxersScreen`
            ),
          );
        } catch (e) {
          print('Error loading approved trainers: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('ไม่สามารถโหลดครูมวยที่ได้รับการอนุมัติได้')),
          );
        }
      }
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    ),
  );
}
