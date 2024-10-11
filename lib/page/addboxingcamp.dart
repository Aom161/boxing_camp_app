import 'dart:io';
import 'package:boxing_camp_app/main.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'map_picker_page.dart';

class AddCampPage extends StatefulWidget {
  final String? username;
  const AddCampPage({super.key, this.username});

  @override
  State<AddCampPage> createState() => _AddCampPageState();
}

class _AddCampPageState extends State<AddCampPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  LatLng? _selectedLocation;
  File? _image;
  late String? username;
  String accessToken = "";
  String refreshToken = "";
  String role = "";
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;
  late String? _id;
  String? campImage;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getInitialize();
    username = widget.username;
  }

  void getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn")!;
      username = prefs.getString("username");
      _id = prefs.getString("_id")!;
      accessToken = prefs.getString("accessToken")!;
      refreshToken = prefs.getString("refreshToken")!;
      role = prefs.getString("role")!;
    });
  }

  Future<String?> _uploadImage() async {
    if (_image == null) return null; // ไม่มีภาพให้แนบ

    String fileExtension = _image!.path.split('.').last.toLowerCase();
    String fileName = '${_id}.$fileExtension';
    Reference storageReference =
        FirebaseStorage.instance.ref().child('uploads/$fileName');

    UploadTask uploadTask = storageReference.putFile(_image!);
    await uploadTask;

    return await storageReference.getDownloadURL();
  }

  Future<void> _submitData() async {
    if (_formKey.currentState?.validate() ?? false) {
      String? selectedManagerId = _id;

      try {
        // อัปโหลดรูปภาพก่อน
        String? imageUrl = await _uploadImage();

        // ตรวจสอบว่าผู้จัดการมีค่ายหรือชื่อค่ายซ้ำ
        final campsResponse = await http.get(
          Uri.parse('$apiUrl/getcamp'),
          headers: {'Content-Type': 'application/json'},
        );

        if (campsResponse.statusCode == 200) {
          List<dynamic> camps = jsonDecode(campsResponse.body);

          // ตรวจสอบว่าผู้จัดการมีค่ายอยู่หรือไม่
          bool isManagerHasCamp =
              camps.any((camp) => camp['manager'] == selectedManagerId);
          if (isManagerHasCamp) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('คุณมีค่ายที่สังกัดอยู่แล้ว ไม่สามารถเพิ่มค่ายได้')),
            );
            return;
          }

          // ตรวจสอบชื่อค่ายที่กรอก
          bool isCampNameTaken =
              camps.any((camp) => camp['name'] == _nameController.text);
          if (isCampNameTaken) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('ชื่อค่ายนี้มีอยู่แล้ว กรุณาใช้ชื่ออื่น')),
            );
            return;
          }
        } else {
          throw Exception('ไม่สามารถตรวจสอบค่ายได้');
        }

        // ดำเนินการต่อถ้าทุกอย่างเรียบร้อย
        final campData = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'location': {
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
          },
          'manager': selectedManagerId,
          'imageUrl': imageUrl, // ใช้ URL ของภาพที่อัปโหลด
        };

        final response = await http.post(
          Uri.parse('$apiUrl/addcamp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(campData),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกค่ายมวยสำเร็จ')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.reasonPhrase}')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $error')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่ได้เลือกรูป')),
      );
    }
  }

  Future<void> _selectLocation() async {
    LatLng? selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerPage(),
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedLocation = selected;
      });
    }
  }

  void _cancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'เพิ่มค่ายมวย',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(248, 226, 131, 53),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFED673),
                          border: Border.all(color: Colors.grey, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        width: double.infinity,
                        height: 150,
                        child: Center(
                          child: _image == null
                              ? campImage == null
                                  ? const Text(
                                      'แตะเพื่อเลือกรูปภาพ',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : Image.network(
                                      campImage!,
                                      width: double.infinity,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    )
                              : Image.file(
                                  _image!,
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('ชื่อค่าย',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'ใส่ชื่อค่าย',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 10),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณาใส่ชื่อค่าย';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('ผู้จัดการค่าย',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(username ?? 'ไม่พบผู้จัดการ',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    const Text('คำอธิบายค่าย',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'ใส่คำอธิบายค่าย',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 10),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณาใส่คำอธิบายค่าย';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('ตำแหน่ง',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectLocation,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _selectedLocation == null
                              ? 'ระบุตำแหน่ง'
                              : 'ตำแหน่ง: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _submitData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 59, 218, 64),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 22),
                            ),
                            child: const Text('บันทึกข้อมูล',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 16)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _cancel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 241, 116, 116),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 22),
                            ),
                            child: const Text('ยกเลิก',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
