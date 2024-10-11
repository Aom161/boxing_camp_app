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

class ManageRequestsPage extends StatefulWidget {
  final String? username;
  const ManageRequestsPage({super.key, this.username});

  @override
  _ManageRequestsPageState createState() => _ManageRequestsPageState();
}

class _ManageRequestsPageState extends State<ManageRequestsPage> {
  List<dynamic> requests = [];
  late String? username;
  late String? _id;
  String accessToken = "";
  String refreshToken = "";
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
      refreshToken = prefs.getString("refreshToken") ?? "";
      role = prefs.getString("role") ?? "";
      _id = prefs.getString("_id");
    });

    // ดึง camp ID สำหรับผู้จัดการ
    managerCampId = await fetchManagerCampId();
    fetchRequests(); // เรียกฟังก์ชัน fetchRequests หลังจากได้ camp ID
  }

  Future<String> fetchManagerCampId() async {
    final response = await http.get(
      Uri.parse(
          '$apiUrl/getcamp'), // API เพื่อดึงข้อมูลค่ายมวยทั้งหมด
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> camps = jsonDecode(response.body);
      String managerId =
          (await SharedPreferences.getInstance()).getString("_id") ??
              ""; // ใช้ await เพื่อดึง ID ผู้ใช้ที่ล็อกอิน

      // กรองค่ายมวยที่มี manager ID ตรงกับผู้จัดการที่ล็อกอิน
      var camp = camps.firstWhere((c) => c['manager'] == managerId, orElse: () {
        throw Exception(
            'ไม่พบค่ายสำหรับผู้จัดการนี้'); // เพิ่มการจัดการข้อผิดพลาด
      });

      return camp['_id'].toString(); // ส่งคืน `_id` ของค่าย
    } else {
      return 'ไม่พบค่าย'; // ส่งคืนข้อความที่คุณต้องการเมื่อไม่พบค่าย
    }
  }

  Future<void> fetchRequests() async {
    setState(() {
      requests.clear();
    });

    final response = await http.get(
      Uri.parse(
          '$apiUrl/getrequest?campId=$managerCampId'), // ส่ง campId ไปใน query string
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Cache-Control': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> allRequests = jsonDecode(response.body);
      setState(() {
        requests = allRequests; // ไม่ต้องกรองเพิ่มในฝั่งไคลเอนต์แล้ว
      });
    } else {
      throw Exception('ไม่สามารถโหลดคำขอได้');
    }
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    final response = await http.patch(
      Uri.parse('$apiUrl/approveordeny/$requestId'),
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
        requests.removeWhere((request) => request['_id'] == requestId);
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
      body: requests.isEmpty
          ? Center(
              child: Text(
                'ไม่มีคำขอที่ส่งมา',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            )
          : ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return ListTile(
                  title: Text('นักมวย: ${request['boxerId']['fullname']}'),
                  subtitle:
                      Text('ค่ายที่ส่งคำขอไป: ${request['campId']['name']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          updateRequestStatus(request['_id'], 'approved');
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          updateRequestStatus(request['_id'], 'denied');
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
