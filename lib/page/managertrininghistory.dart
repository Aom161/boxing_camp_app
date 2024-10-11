import 'dart:io';
import 'package:boxing_camp_app/page/boxeractivitypage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boxing_camp_app/variable.dart';

class ManagerActivityHistoryPage extends StatefulWidget {
  final String? username;

  const ManagerActivityHistoryPage({super.key, this.username});

  @override
  _ManagerActivityHistoryPageState createState() =>
      _ManagerActivityHistoryPageState();
}

class _ManagerActivityHistoryPageState
    extends State<ManagerActivityHistoryPage> {
  String? username;
  String accessToken = "";
  String role = "";
  late String _id;
  bool _isCheckingStatus = false;
  List<dynamic> activities = [];
  Map<String, String> userNamesById = {};
  Map<String, String> boxerNamesById = {};
  List<String> uniqueBoxerIds = []; // List to store unique boxer IDs

  @override
  void initState() {
    super.initState();
    getInitialize();
    _fetchActivities();
  }

  void getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn") ?? false;
      username = prefs.getString("username");
      accessToken = prefs.getString("accessToken") ?? "";
      role = prefs.getString("role") ?? "";
      _id = prefs.getString('_id') ?? "";
    });
  }

  Future<void> _fetchActivities() async {
    final url = Uri.parse('$apiUrl/gettraining');
    try {
      final response = await http.get(url, headers: {
        HttpHeaders.authorizationHeader: "Bearer $accessToken",
      });

      if (response.statusCode == 200) {
        final fetchedActivities = jsonDecode(response.body);
        setState(() {
          activities = fetchedActivities;
          uniqueBoxerIds =
              _getUniqueBoxerIds(fetchedActivities); // Get unique boxer IDs
        });

        await _fetchUserNames(activities);
        await _fetchBoxerNames(activities);
      } else {
        print('Failed to load activities. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching activities: $error');
    }
  }

  List<String> _getUniqueBoxerIds(List<dynamic> activities) {
    final Set<String> uniqueIds = {};
    for (var activity in activities) {
      final boxerId = activity['boxerId'];
      if (boxerId != null) {
        uniqueIds.add(boxerId);
      }
    }
    return uniqueIds.toList(); // Convert Set to List
  }

  Future<void> _fetchBoxerNames(List<dynamic> activities) async {
    for (var activity in activities) {
      final boxerId = activity['boxerId'];
      if (boxerId != null && !boxerNamesById.containsKey(boxerId)) {
        final boxerName = await _fetchBoxerName(boxerId);
        if (boxerName != null) {
          setState(() {
            boxerNamesById[boxerId] = boxerName;
          });
        }
      }
    }
  }

  Future<String?> _fetchBoxerName(String boxerId) async {
    final url = Uri.parse('$apiUrl/getUserById/$boxerId');
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

  Future<void> _fetchUserNames(List<dynamic> activities) async {
    for (var activity in activities) {
      final userId = activity['userId']['_id'];
      if (userId != null && !userNamesById.containsKey(userId)) {
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
        print('Failed to load user. Status code: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error fetching user: $error');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ประวัติการฝึกซ้อม',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
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
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView.builder(
        itemCount: uniqueBoxerIds.length,
        itemBuilder: (context, index) {
          final boxerId = uniqueBoxerIds[index];
          final boxerName = boxerNamesById[boxerId] ?? 'Unknown Boxer';

          return Card(
            margin: const EdgeInsets.all(8.0),
            elevation: 4.0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BoxerActivityHistoryPage(
                        boxerId: boxerId,
                        username: username ?? 'ผู้ใช้ไม่รู้จัก',
                      ),
                    ),
                  );
                },
                child: Text(
                  'นักมวย: $boxerName',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
