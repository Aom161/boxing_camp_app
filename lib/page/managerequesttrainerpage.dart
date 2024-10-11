import 'dart:convert';
import 'package:boxing_camp_app/main.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = '$apiUrl/getcamp'; // ปรับ URL ให้ถูกต้อง

  Future<List<dynamic>> fetchCamps() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load camps');
    }
  }
}

class ManageRequestsTrainerPage extends StatefulWidget {
  final String? username;
  const ManageRequestsTrainerPage({Key? key, this.username}) : super(key: key);

  @override
  _ManageRequestsTrainerPageState createState() =>
      _ManageRequestsTrainerPageState();
}

class _ManageRequestsTrainerPageState extends State<ManageRequestsTrainerPage> {
  List<dynamic> trainerrequests = [];
  late String? username;
  late String? _id;
  String accessToken = "";
  String role = "";
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;
  late String managerCampId;

  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    username = widget.username;
    getInitialize();
  }

  Future<void> getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn") ?? false;
      username = prefs.getString("username");
      accessToken = prefs.getString("accessToken") ?? "";
      role = prefs.getString("role") ?? "";
      _id = prefs.getString("_id");
    });

    // ดึง camp ID สำหรับผู้จัดการ
    managerCampId = await fetchManagerCampId();
    fetchRequests(); // เรียกฟังก์ชัน fetchRequests หลังจากได้ camp ID
  }

  Future<String> fetchManagerCampId() async {
    // API สำหรับดึงค่ายที่ผู้จัดการเป็นเจ้าของ
    final response = await http.get(
      Uri.parse('$apiUrl/getcamp'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> camps = jsonDecode(response.body);
      String managerId =
          (await SharedPreferences.getInstance()).getString("_id") ?? "";

      // กรองค่ายมวยที่มี manager ID ตรงกับผู้จัดการที่ล็อกอิน
      var camp = camps.firstWhere((c) => c['manager'] == managerId, orElse: () {
        throw Exception('ไม่พบค่ายสำหรับผู้จัดการนี้');
      });

      return camp['_id'].toString(); // ส่งคืน `_id` ของค่าย
    } else {
      throw Exception('ไม่พบค่าย'); // ส่งคืนข้อความที่คุณต้องการเมื่อไม่พบค่าย
    }
  }

  Future<void> fetchRequests() async {
    setState(() {
      trainerrequests.clear();
    });

    final response = await http.get(
      Uri.parse(
          '$apiUrl/trainergetrequest?campId=$managerCampId'), // ส่ง campId ไปใน query string
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Cache-Control': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> allRequests = jsonDecode(response.body);
      setState(() {
        trainerrequests = allRequests; // ไม่ต้องกรองเพิ่มในฝั่งไคลเอนต์แล้ว
      });
    } else {
      throw Exception('ไม่สามารถโหลดคำขอได้');
    }
  }

  Future<void> updateRequestStatus(
      String trainerrequestId, String status) async {
    final response = await http.patch(
      Uri.parse('$apiUrl/trainerapproveordeny/$trainerrequestId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $status successfully!')),
      );

      // ลบคำขอออกจาก requests หากสถานะคือ approved หรือ denied
      setState(() {
        trainerrequests.removeWhere(
            (trainerrequest) => trainerrequest['_id'] == trainerrequestId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update request.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Requests'),
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
      body: trainerrequests.isEmpty
          ? Center(
              child: Text(
                'ไม่มีคำขอที่ส่งมา',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            )
          : ListView.builder(
              itemCount: trainerrequests.length,
              itemBuilder: (context, index) {
                final trainerrequest = trainerrequests[index];
                return ListTile(
                  title: Text(
                      'ครูมวย: ${trainerrequest['trainerId']['fullname']}'),
                  subtitle: Text(
                      'ค่ายที่ส่งคำขอไป: ${trainerrequest['campId']['name']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          updateRequestStatus(
                              trainerrequest['_id'], 'approved');
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          updateRequestStatus(trainerrequest['_id'], 'denied');
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
