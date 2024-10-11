import 'dart:convert';
import 'package:boxing_camp_app/main.dart';
import 'package:boxing_camp_app/page/campdetail.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = '$apiUrl/getcamp';

  Future<List<dynamic>> fetchCamps() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load camps');
    }
  }
}

class CampUser extends StatefulWidget {
  final String? username;

  const CampUser({super.key, this.username});

  @override
  _CampUserState createState() => _CampUserState();
}

class _CampUserState extends State<CampUser> {
  String accessToken = "";
  String refreshToken = "";
  String role = "";
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;
  String? username;

  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    username = widget.username;
    getInitialize();
  }

  Future<List<dynamic>> _fetchCamps() async {
    return await apiService.fetchCamps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ค่ายมวย',
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
      body: FutureBuilder<List<dynamic>>(
        future: _fetchCamps(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีค่ายมวย'));
          } else {
            final camps = snapshot.data!;
            return ListView.builder(
              itemCount: camps.length,
              itemBuilder: (context, index) {
                final camp = camps[index];

                final imageUrl = camp['image_url'] ?? 'https://via.placeholder.com/150';
                final campName = camp['name'] ?? 'ไม่มีชื่อค่าย';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CampDetailScreen(camp: camp),
                        ),
                      );
                    },
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFED673),
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
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            imageUrl,
                            height: 150.0,
                            width: 150.0,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            campName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<void> getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn")!;
      username = prefs.getString("username");
      accessToken = prefs.getString("accessToken")!;
      refreshToken = prefs.getString("refreshToken")!;
      role = prefs.getString("role")!;
    });
  }
}
