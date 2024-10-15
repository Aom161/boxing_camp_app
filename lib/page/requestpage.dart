import 'dart:convert';
import 'package:boxing_camp_app/main.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RequestToJoinCampPage extends StatefulWidget {
  final String? username;

  const RequestToJoinCampPage({super.key, this.username});

  @override
  _RequestToJoinCampPageState createState() => _RequestToJoinCampPageState();
}

class _RequestToJoinCampPageState extends State<RequestToJoinCampPage> {
  String? selectedCampId;
  List<dynamic> camps = [];
  List<dynamic> requests = [];
  String accessToken = "";
  String role = "";
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;
  String? username;
  String? _id;
  String? currentRequestStatus;
  bool isLoadingCamps = true;
  bool isLoadingRequests = true;

  @override
  void initState() {
    super.initState();
    username = widget.username;
    getInitialize();
    fetchCamps();
    fetchRequest();
  }

  void getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn") ?? false;
      username = prefs.getString("username") ?? "";
      accessToken = prefs.getString("accessToken") ?? "";
      role = prefs.getString("role") ?? "";
      _id = prefs.getString('_id') ?? "";
    });
  }

  Future<void> fetchCamps() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/getcamp'));
      if (response.statusCode == 200) {
        setState(() {
          camps = jsonDecode(response.body);
          isLoadingCamps = false;
        });
      } else {
        throw Exception('ไม่สามารถโหลดค่ายได้');
      }
    } catch (e) {
      setState(() {
        isLoadingCamps = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> fetchRequest() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/getRequestToAll'));
      if (response.statusCode == 200) {
        setState(() {
          List<dynamic> allRequests = jsonDecode(response.body);
          String? currentUserId = _id;

          // ดึงเฉพาะคำขอของผู้ใช้ปัจจุบัน
          requests = allRequests
              .where((request) => request['boxerId']['_id'] == currentUserId)
              .toList();

          // อัปเดต currentRequestStatus ตามสถานะของคำขอ
          if (requests.isNotEmpty) {
            // ตรวจสอบว่ามีคำขอที่ได้รับการอนุมัติหรือไม่
            var approvedRequest = requests.firstWhere(
                (request) => request['status'] == 'approved',
                orElse: () => null);

            if (approvedRequest != null) {
              currentRequestStatus = 'คำขอของคุณได้รับการอนุมัติแล้ว';
            } else {
              currentRequestStatus = 'คำขอของคุณอยู่ในขั้นตอนการตรวจสอบ';
            }
          } else {
            currentRequestStatus = null;
          }

          isLoadingRequests = false;
        });

        print("---------------------------");
        print(requests);
        print("---------------------------");
      } else {
        throw Exception('ไม่สามารถโหลดคำขอได้');
      }
    } catch (e) {
      setState(() {
        isLoadingRequests = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<String?> getRequestStatus(String boxerId, String campId) async {
    final response = await http.get(
      Uri.parse('$apiUrl/getRequestStatus?boxerId=$boxerId&campId=$campId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'];
    } else if (response.statusCode == 404) {
      return null; // No request found
    } else {
      throw Exception('ไม่สามารถตรวจสอบสถานะคำขอได้');
    }
  }

  Future<void> submitRequest(String boxerId, String campId) async {
    // Fetch current requests to check if a request exists before submission
    await fetchRequest(); // Fetch requests to get the latest status

    // Check if the currentRequestStatus is set, indicating an existing request
    if (currentRequestStatus != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(currentRequestStatus!)),
      );
      return; // Prevent further requests
    }

    if (accessToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access token is missing!')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'boxerId': boxerId, 'campId': campId}),
      );

      if (response.statusCode == 201) {
        // Refresh requests to update the UI
        await fetchRequest(); // Ensure the latest requests are fetched
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งคำขอสำเร็จ!')),
        );
      } else {
        String errorMessage = 'ไม่สามารถส่งคำขอได้';
        if (response.statusCode == 401) {
          errorMessage = 'Unauthorized: Invalid access token.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String boxerId = _id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('คำขอเข้าร่วมค่าย'),
        backgroundColor: const Color.fromARGB(248, 226, 131, 53),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เลือกค่ายที่ต้องการเข้าร่วม:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            isLoadingCamps
                ? Center(child: CircularProgressIndicator())
                : camps.isEmpty
                    ? Center(child: Text('ไม่มีค่ายให้เลือก'))
                    : DropdownButton<String>(
                        value: selectedCampId,
                        isExpanded: true,
                        hint: Text('เลือกค่าย'),
                        items: camps.map<DropdownMenuItem<String>>((camp) {
                          return DropdownMenuItem<String>(
                            value: camp['_id'] ?? '',
                            child: Text(camp['name'] ?? 'Unknown Camp'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCampId = value;
                          });
                        },
                      ),
            SizedBox(height: 24),
            if (currentRequestStatus != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  currentRequestStatus!,
                  style: TextStyle(
                    color:
                        currentRequestStatus == 'คำขอของคุณได้รับการอนุมัติแล้ว'
                            ? Colors.green // สีเขียวเมื่อได้รับการอนุมัติ
                            : Colors.red, // สีแดงเมื่ออยู่ระหว่างการตรวจสอบ
                    fontSize: 16,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: selectedCampId == null ||
                      selectedCampId!.isEmpty ||
                      currentRequestStatus !=
                          null // Disable button if an existing request exists
                  ? null
                  : () {
                      submitRequest(boxerId, selectedCampId!);
                    },
              child: Text('ส่งคำขอ'),
            ),
          ],
        ),
      ),
    );
  }
}
