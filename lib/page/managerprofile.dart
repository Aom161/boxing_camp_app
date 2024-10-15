import 'dart:io';
import 'package:boxing_camp_app/main.dart';
import 'package:boxing_camp_app/page/editprofile.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ManagerProfilePage extends StatefulWidget {
  final String? username;

  const ManagerProfilePage({super.key, this.username});

  @override
  _ManagerProfilePageState createState() => _ManagerProfilePageState();
}

class _ManagerProfilePageState extends State<ManagerProfilePage> {
  late String? username;
  late String? _id;
  String accessToken = "";
  String refreshToken = "";
  String role = "";
  String telephone = "";
  String address = "";
  String email = "";
  String fullname = "";
  String? profileImage;
  String? campName;
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;
  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    username = widget.username;
    getInitialize();
  }

  void getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn") ?? false;
      username = prefs.getString("username") ?? "No Username";
      accessToken = prefs.getString("accessToken") ?? "";
      refreshToken = prefs.getString("refreshToken") ?? "";
      role = prefs.getString("role") ?? "No Role";
      _id = prefs.getString('_id');
    });

    if (accessToken.isNotEmpty) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (_id != null && accessToken.isNotEmpty) {
      await _fetchUserData();
      await _fetchCampData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final userResponse = await http.get(
        Uri.parse('$apiUrl/getUserById/${_id}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (userResponse.statusCode == 200) {
        final data = jsonDecode(userResponse.body);
        setState(() {
          username = data['username'] ?? 'ไม่มีชื่อผู้ใช้';
          telephone = data['telephone'] ?? 'ไม่มีเบอร์โทร';
          address = data['address'] ?? 'ไม่มีที่อยู่';
          email = data['email'] ?? 'ไม่มีอีเมล';
          fullname = data['fullname'] ?? 'ไม่มีชื่อ';
          profileImage = data['profile_img'];
        });
      }
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _fetchCampData() async {
    try {
      final requestResponse = await http.get(
        Uri.parse('$apiUrl/getcamp'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (requestResponse.statusCode == 200) {
        final requestData = jsonDecode(requestResponse.body);
        if (requestData is List) {
          bool found = false;
          for (var request in requestData) {
            if (request['manager'] == _id) {
              setState(() {
                campName = request['name'] ?? 'ไม่มีค่าย';
              });
              found = true;
              break;
            }
          }
          if (!found) {
            setState(() {
              campName = 'ไม่มีค่าย';
            });
          }
        }
      }
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _pickImage() async {
    // Request permission to access the gallery (if needed)
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    // Check if a file was picked
    if (pickedFile != null) {
      setState(() {
        _image =
            File(pickedFile.path); // Update the state with the selected image
      });
    } else {
      // Optional: Show a message if no image was selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่ได้เลือกรูป')),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected.')),
      );
      return;
    }

    String fileExtension = _image!.path.split('.').last.toLowerCase();
    String fileName = '${_id}.$fileExtension';

    Reference storageReference =
        FirebaseStorage.instance.ref().child('uploads/$fileName');

    UploadTask uploadTask = storageReference.putFile(_image!);
    await uploadTask;

    String downloadUrl = await storageReference.getDownloadURL();

    // Update the MongoDB document with the new image URL
    await _updateUserProfileImage(downloadUrl);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('อัพโหลดรูปสำเร็จ')),
    );
  }

  Future<void> _updateUserProfileImage(String imageUrl) async {
    try {
      final response = await http.patch(
        Uri.parse('$apiUrl/updateUserImage/${_id}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'profile_img': imageUrl}),
      );

      if (response.statusCode == 200) {
        // Successfully updated the user's profile image
        setState(() {
          profileImage = imageUrl; // Update local state
        });
      } else {
        // Handle error response
        print('Error updating profile image: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile image.')),
        );
      }
    } catch (e) {
      print('Error updating profile image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'โปรไฟล์ของฉัน',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(248, 226, 131, 53),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  _image == null
                      ? profileImage == null
                          ? CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.black,
                              ),
                            )
                          : ClipOval(
                              child: Image.network(
                                profileImage!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                      : ClipOval(
                          child: Image.file(
                            _image!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                  
                  
                  // ปุ่มเลือกรูปและอัปโหลดรูป
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 170), // ระยะห่างจากรูป
                   Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        onPressed: _pickImage,
                        tooltip: 'เลือกรูป',
                        child: const Icon(Icons.add_a_photo),
                        backgroundColor: const Color.fromARGB(255, 82, 168, 238),
                        shape: const CircleBorder(),
                      ),
                      const SizedBox(width: 20), // ระยะห่างระหว่างปุ่ม
                      FloatingActionButton(
                        onPressed: _uploadImage,
                        tooltip: 'อัปโหลดรูป',
                        child: const Icon(Icons.upload_file),
                        backgroundColor: const Color.fromARGB(255, 100, 228, 104),
                        shape: const CircleBorder(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30), // เพิ่มระยะห่างระหว่างปุ่มและรูปโปรไฟล์
                  ],
                ),
                


                ],
              ),
              const SizedBox(height: 20),
              Text(
                fullname,
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                username!,
                style: const TextStyle(fontSize: 24, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFED673),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.account_circle, fullname),
                    _buildInfoRow(Icons.phone, telephone),
                    _buildInfoRow(Icons.location_on, address),
                    _buildInfoRow(Icons.security, role),
                    _buildInfoRow(Icons.group, campName ?? 'ไม่มีค่าย'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfile(
                        userData: {
                          'username': username,
                          'telephone': telephone,
                          'address': address,
                          'email': email,
                          'fullname': fullname,
                        },
                      ),
                    ),
                  );

                  if (result == true) {
                    _loadUserData();
                  }
                },
                child: const Text('แก้ไขโปรไฟล์'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String info) {
    return Row(
      children: [
        Icon(icon, color: Colors.black, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            info,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ],
    );
  }
}

extension on ImagePicker {
  getImage({required ImageSource source}) {}
}
