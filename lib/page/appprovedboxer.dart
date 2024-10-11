import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApprovedBoxersScreen extends StatefulWidget {
  final String campId;

  const ApprovedBoxersScreen({super.key, required this.campId});

  @override
  _ApprovedBoxersScreenState createState() => _ApprovedBoxersScreenState();
}

class _ApprovedBoxersScreenState extends State<ApprovedBoxersScreen> {
  late Future<List<dynamic>> approvedBoxers;

  // ฟังก์ชันเพื่อดึงข้อมูลนักมวยที่ได้รับการอนุมัติ
  Future<List<dynamic>> fetchApprovedBoxers() async {
    final response = await http.get(
      Uri.parse('$apiUrl/getApprovedBoxers/${widget.campId}'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load approved boxers');
    }
  }

  @override
  void initState() {
    super.initState();
    approvedBoxers = fetchApprovedBoxers(); // เริ่มดึงข้อมูลตอนเริ่มต้น
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('นักมวยที่ได้รับการอนุมัติ'),
        backgroundColor: const Color.fromARGB(248, 226, 131, 53),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: approvedBoxers, // ใช้ FutureBuilder เพื่อแสดงข้อมูล
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('ยังไม่มีนักมวยที่ได้รับการอนุมัติ'));
          } else {
            // แสดงรายการนักมวยที่ได้รับการอนุมัติ
            final boxers = snapshot.data!;
            return ListView.builder(
              itemCount: boxers.length,
              itemBuilder: (context, index) {
                final boxer = boxers[index];
                return ListTile(
                  title: Text(boxer['fullname'] ?? 'ไม่มีชื่อ'),
                  subtitle: Text(boxer['username'] ?? 'ไม่มีชื่อผู้ใช้'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
