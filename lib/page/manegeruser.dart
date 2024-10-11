import 'dart:convert';
import 'package:boxing_camp_app/main.dart';
import 'package:boxing_camp_app/models/user.dart';
import 'package:boxing_camp_app/page/edituser.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Manegeruser extends StatefulWidget {
  final String? username;
  const Manegeruser({super.key, this.username});

  @override
  _ManegeruserState createState() => _ManegeruserState();
}

class _ManegeruserState extends State<Manegeruser> {
  late Future<List<User>> futureUsers;
  late String? username;
  String accessToken = "";
  String refreshToken = "";
  String role = "";
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    futureUsers = fetchUsers();
    username = widget.username;
    getInitialize();
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

  Future<List<User>> fetchUsers() async {
    final response = await http.get(
      Uri.parse('$apiUrl/users'),
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> usersJson = json.decode(response.body);
      final List<User> users = usersJson
          .map((json) => User.fromJson(json))
          .where((user) => user.role == 'ผู้จัดการค่ายมวย')
          .toList();
      return users;
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<void> deleteUser(String id) async {
    final response = await http.delete(
      Uri.parse('$apiUrl/deleteuser/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        futureUsers = fetchUsers();
      });
    } else {
      throw Exception('Failed to delete user');
    }
  }

  void _editUser(User user) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditUserScreen(user: user),
    ),
  );

  if (result == true) {
    setState(() {
      futureUsers = fetchUsers();
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'รายชื่อผู้จัดการค่ายมวย',
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
      body: Center(
        child: FutureBuilder<List<User>>(
          future: futureUsers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No data found');
            } else {
              final users = snapshot.data!;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(users[index].fullname),
                    subtitle: Text(users[index].email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editUser(users[index]),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmDelete(users[index]),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  void _confirmDelete(User user) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบ ${user.fullname}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await deleteUser(user.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.fullname} ถูกลบเรียบร้อยแล้ว')),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}
}