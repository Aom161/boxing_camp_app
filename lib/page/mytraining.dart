import 'dart:io';
import 'package:boxing_camp_app/main.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingHistoryPage extends StatefulWidget {
  final String? username;

  const TrainingHistoryPage({super.key, this.username});

  @override
  _TrainingHistoryPageState createState() => _TrainingHistoryPageState();
}

class _TrainingHistoryPageState extends State<TrainingHistoryPage> {
  String? username;
  String accessToken = "";
  String refreshToken = "";
  String role = "";
  late String _id;
  bool _isCheckingStatus = false;
  List<dynamic> activities = [];
  Map<String, String> userNamesById = {};

  @override
  void initState() {
    super.initState();
    getInitialize();
    _fetchActivities();
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
    print(username);
    print(accessToken);
    print(refreshToken);
    print(role);
  }

  Future<List<dynamic>> _fetchActivities() async {
    final url = Uri.parse('$apiUrl/gettraining');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final fetchedActivities = jsonDecode(response.body);

        // Filter activities to only show the logged-in boxer's history
        final filteredActivities = fetchedActivities.where((activity) {
          return activity['boxerId'] == _id;
        }).toList();

        setState(() {
          activities = filteredActivities;
        });

        await _fetchUserNames(filteredActivities);
        await _fetchBoxerNames(fetchedActivities);
        return activities;
      } else {
        print('Failed to load activities. Status code: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error fetching activities: $error');
      return [];
    }
  }

  Future<void> _fetchUserNames(List<dynamic> activities) async {
    for (var activity in activities) {
      final userId = activity['userId']['_id'];
      if (userId != null) {
        final userName = await _fetchUserName(userId);
        if (userName != null) {
          setState(() {
            userNamesById[userId] = userName;
          });
        }
      }
    }
  }

  Future<void> _fetchBoxerNames(List<dynamic> activities) async {
    for (var activity in activities) {
      final boxerId = activity['boxerId'];
      if (boxerId != null) {
        final boxerName = await _fetchBoxerName(boxerId);
        if (boxerName != null) {
          setState(() {
            userNamesById[boxerId] = boxerName;
          });
        }
      }
    }
  }

  Future<String?> _fetchBoxerName(String boxerId) async {
    final url = Uri.parse('$apiUrl/getUserById/${boxerId}');
    try {
      final response = await http.get(url, headers: {
        HttpHeaders.authorizationHeader: "Bearer $accessToken",
      });
      if (response.statusCode == 200) {
        final boxer = jsonDecode(response.body);
        return boxer['fullname'];
      } else {
        print('Failed to load boxer. Status code: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error fetching boxer: $error');
      return null;
    }
  }

  Future<String?> _fetchUserName(String userId) async {
    final url = Uri.parse('$apiUrl/getUserById/${userId}');
    try {
      final response = await http.get(url, headers: {
        HttpHeaders.authorizationHeader: "Bearer $accessToken",
      });
      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        return user['fullname'];
      } else {
        if (response.statusCode == 403) {
          // Handle token refresh logic here
        } else if (response.statusCode == 401) {
          // Handle logout logic
          _handleLogout();
        }
        print('Failed to load user. Status code: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error fetching user: $error');
      return null;
    }
  }

  void _handleLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored preferences
    Navigator.pushReplacementNamed(context, '/login'); // Redirect to login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ประวัติการฝึกซ้อม',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
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
      body: activities.isEmpty
          ? const Center(
              child: Text(
                'ไม่มีข้อมูลการฝึกซ้อม',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                final running = activity['running'] ?? {};
                final ropeJumping = activity['ropeJumping'] ?? {};
                final punching = activity['punching'] ?? {};
                final weightTraining = activity['weightTraining'] ?? {};
                final updatedAt = activity['updated_at'];

                // ดึง boxerId เพื่อใช้ในการหาชื่อนักมวย
                final boxerId = activity['boxerId'];
                final boxerName = userNamesById[boxerId] ??
                    'ไม่ทราบชื่อ'; // กำหนดชื่อ "ไม่ทราบชื่อ" หากหาไม่เจอ

                final formattedDate = updatedAt != null
                    ? DateTime.parse(updatedAt.toString())
                        .toLocal()
                        .toString()
                        .split(' ')[0]
                    : 'Unknown date';

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // แสดงชื่อของนักมวยก่อนการแสดงรายละเอียดการฝึกซ้อม
                        Text(
                          'การฝึกซ้อมของ: $boxerName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (running.isNotEmpty &&
                            (running['duration'] != null ||
                                running['distance'] != null))
                          Text(
                            'วิ่ง: ${running['duration']} นาที, ระยะทาง: ${running['distance']} กม.',
                            style: const TextStyle(fontSize: 16),
                          ),
                        if (ropeJumping.isNotEmpty &&
                            (ropeJumping['duration'] != null ||
                                ropeJumping['count'] != null))
                          Text(
                            'กระโดดเชือก: ${ropeJumping['duration']} นาที, จำนวนครั้ง: ${ropeJumping['count']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        if (punching.isNotEmpty &&
                            (punching['duration'] != null ||
                                punching['count'] != null))
                          Text(
                            'การชกกระสอบทราย: ${punching['duration']} นาที, จำนวนครั้ง: ${punching['count']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        if (weightTraining.isNotEmpty &&
                            (weightTraining['duration'] != null ||
                                weightTraining['count'] != null))
                          Text(
                            'ยกน้ำหนัก: ${weightTraining['duration']} นาที, จำนวนครั้ง: ${weightTraining['count']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        Text(
                          'วันที่บันทึกข้อมูล: $formattedDate',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
