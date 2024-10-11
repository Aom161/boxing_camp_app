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

class TrainerProfilePage extends StatefulWidget {
  final String? username;

  const TrainerProfilePage({super.key, this.username});

  @override
  _TrainerProfilePageState createState() => _TrainerProfilePageState();
}

class _TrainerProfilePageState extends State<TrainerProfilePage> {
  late String? username;
  late String? _id;
  String accessToken = "";
  String refreshToken = "";
  String role = "";
  String telephone = "";
  String address = "";
  String email = ""; // Add email
  String fullname = ""; // Add fullname
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;
  File? _image;
  String? campName;
  late String? trainerId;
  String? profileImage;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    username = widget.username;
    getInitialize();
    _loadUserData();
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

    print(_isCheckingStatus);
    print(username);
    print(accessToken);
    print(refreshToken);
    print(role);
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    if (token != null && _id != null) {
      try {
        // เรียกดูข้อมูลผู้ใช้
        final userResponse = await http.get(
          Uri.parse('$apiUrl/getUserById/${_id}'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (userResponse.statusCode == 200) {
          final data = jsonDecode(userResponse.body);

          setState(() {
            username = data['username']?.toString() ?? 'ไม่มีชื่อผู้ใช้';
            telephone = data['telephone']?.toString() ?? 'ไม่มีเบอร์โทร';
            address = data['address']?.toString() ?? 'ไม่มีที่อยู่';
            email = data['email']?.toString() ?? 'ไม่มีอีเมล';
            fullname = data['fullname']?.toString() ?? 'ไม่มีชื่อ';
            profileImage = data['profile_img'];
          });

          // ดึงข้อมูลค่ายจาก request
          final requestResponse = await http.get(
            Uri.parse('$apiUrl/getalltrainerrequest'),
            headers: {
              'Authorization': 'Bearer $token',
            },
          );

          if (requestResponse.statusCode == 200) {
            final requestData = jsonDecode(requestResponse.body);

            // ตรวจสอบว่า requestData เป็น List หรือไม่
            if (requestData is List) {
              bool found = false;

              for (var request in requestData) {
                // ตรวจสอบว่า boxerId ตรงกับ _id หรือไม่
                String trainerIdString = request['trainerId']['_id'] ??
                    ''; // Assuming boxerId is a BSON ObjectId
                String status = request['status']?.toString() ??
                    ''; // Get the status of the request

                // Check if the boxerId matches and the status is approved
                if (trainerIdString == _id && status == 'approved') {
                  setState(() {
                    campName = request['campId']['name']?.toString() ??
                        'ไม่มีค่าย'; // Set the camp name
                  });
                  found = true;
                  break; // หยุดการวน loop เมื่อเจอ
                }
              }

              if (!found) {
                setState(() {
                  campName = 'ไม่มีค่าย'; // กรณีที่ไม่พบข้อมูลค่าย
                });
              }
            } else {
              setState(() {
                campName = 'ไม่มีค่าย'; // กรณีที่ไม่พบข้อมูลค่าย
              });
            }
          } else {
            setState(() {
              campName = 'ไม่มีค่าย'; // กรณีที่ไม่พบข้อมูลค่าย
            });
          }
        } else {
          print(
              'เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้: ${userResponse.statusCode}');
        }
      } catch (e) {
        print('เกิดข้อผิดพลาด: $e');
      }
    } else {
      print('Token หรือ _id เป็น null');
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
        SnackBar(content: Text('ไม่ได้เลือกรูป')),
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
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
                Positioned(
                  bottom: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Positioned(
                        bottom: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_a_photo),
                              onPressed: _pickImage,
                              tooltip: 'เลือกรูป',
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.upload_file),
                              onPressed: _uploadImage,
                              tooltip: 'อัปโหลดรูป',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: Text(
                username!, // Display fullname
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: MediaQuery.of(context).size.height * 0.4, // Adjust height
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFED673),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 20),
                        const Icon(
                          Icons.account_circle,
                          color: Colors.black,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            fullname,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(width: 20),
                        const Icon(
                          Icons.phone,
                          color: Colors.black,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            telephone,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(width: 20),
                        const Icon(
                          Icons.location_on,
                          color: Colors.black,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(width: 20),
                        const Icon(
                          Icons.security,
                          color: Colors.black,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            role, // Display the user's role
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(width: 20),
                        const Icon(
                          Icons.group,
                          color: Colors.black,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            campName ?? 'ไม่มีค่าย', // Display the camp name
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
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

                // Check if the profile was updated
                if (result == true) {
                  _loadUserData(); // Reload user data
                }
              },
              child: const Text('แก้ไขโปรไฟล์'),
            ),
          ],
        ),
      ),
    );
  }
}
