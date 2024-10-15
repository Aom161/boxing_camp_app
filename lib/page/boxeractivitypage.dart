import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BoxerActivityHistoryPage extends StatefulWidget {
  final String boxerId;
  final String username;

  const BoxerActivityHistoryPage({
    super.key,
    required this.boxerId,
    required this.username,
  });

  @override
  _BoxerActivityHistoryPage createState() => _BoxerActivityHistoryPage();
}

class _BoxerActivityHistoryPage extends State<BoxerActivityHistoryPage> {
  late String username;
  late String boxerId;
  String accessToken = "";
  bool _isCheckingStatus = false;
  List<dynamic> activities = [];
  Map<String, String> userNamesById = {};

  @override
  void initState() {
    super.initState();
    getInitialize();
    boxerId = widget.boxerId;
    _fetchBoxerActivities();
  }

  void getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn") ?? false;
      username = prefs.getString("username") ?? "";
      accessToken = prefs.getString("accessToken") ?? "";
    });
  }

  Future<void> _fetchBoxerActivities() async {
    final url = Uri.parse('$apiUrl/gettraining');
    final response = await http.get(url, headers: {
      HttpHeaders.authorizationHeader: "Bearer $accessToken",
    });

    if (response.statusCode == 200) {
      final fetchedActivities = jsonDecode(response.body);
      // กรองกิจกรรมให้ตรงกับ boxerId
      final filteredActivities = fetchedActivities.where((activity) {
        return activity['boxerId'] == boxerId; // เช็คว่า boxerId ตรงกันไหม
      }).toList();

      setState(() {
        activities = filteredActivities;
      });
      await _fetchUserNames(filteredActivities);
    } else {
      throw Exception('โหลดกิจกรรมไม่สำเร็จ');
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

  Future<String?> _fetchUserName(String userId) async {
    final url = Uri.parse('$apiUrl/getUserById/$userId');
    try {
      final response = await http.get(url, headers: {
        HttpHeaders.authorizationHeader: "Bearer $accessToken",
      });
      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        return user['fullname'];
      } else {
        return null;
      }
    } catch (error) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ประวัติการฝึกซ้อมของนักมวย'),
      ),
      body: activities.isEmpty
          ? Center(child: Text('ไม่พบข้อมูลการฝึกซ้อมสำหรับนักมวยนี้'))
          : ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                final running = activity['running'] ?? {};
                final ropeJumping = activity['ropeJumping'] ?? {};
                final punching = activity['punching'] ?? {};
                final weightTraining = activity['weightTraining'] ?? {};
                final updatedAt = activity['updated_at'];

                final userId = activity['userId']['_id'];
                final formattedDate = updatedAt != null
                    ? DateTime.parse(updatedAt.toString())
                        .toLocal()
                        .toString()
                        .split(' ')[0]
                    : 'Unknown date';

                final userName = userNamesById[userId] ?? 'Unknown User';

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  elevation: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ผู้เพิ่มข้อมูล: $userName',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        
                        if (running.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.directions_run),  // ไอคอนวิ่ง
                              const SizedBox(width: 8),
                              Text(
                                'วิ่ง: ${running['duration']} นาที, ระยะทาง: ${running['distance']} กม.',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        
                        if (ropeJumping.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.sports_kabaddi),  // ไอคอนกระโดดเชือก
                              const SizedBox(width: 8),
                              Text(
                                'กระโดดเชือก: ${ropeJumping['duration']} นาที, จำนวนครั้ง: ${ropeJumping['count']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        
                        if (punching.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.sports_mma),  // ไอคอนการชกกระสอบทราย
                              const SizedBox(width: 8),
                              Text(
                                'การชกกระสอบทราย: ${punching['duration']} นาที, จำนวนครั้ง: ${punching['count']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        
                        if (weightTraining.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.fitness_center),  // ไอคอนยกน้ำหนัก
                              const SizedBox(width: 8),
                              Text(
                                'ยกน้ำหนัก: ${weightTraining['duration']} นาที, จำนวนครั้ง: ${weightTraining['count']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        
                        Text(
                          'วันที่บันทึกข้อมูล: $formattedDate',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
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
