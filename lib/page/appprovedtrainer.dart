import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApprovedTrainersScreen extends StatefulWidget {
  final String campId;

  const ApprovedTrainersScreen({super.key, required this.campId});

  @override
  _ApprovedTrainersScreenState createState() => _ApprovedTrainersScreenState();
}

class _ApprovedTrainersScreenState extends State<ApprovedTrainersScreen> {
  late Future<List<dynamic>> approvedTrainers;

  // ฟังก์ชันเพื่อดึงข้อมูลครูมวยที่ได้รับการอนุมัติ
  Future<List<dynamic>> fetchApprovedTrainers() async {
    final response = await http.get(
      Uri.parse('$apiUrl/getApprovedTrainers/${widget.campId}'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load approved trainers');
    }
  }

  @override
  void initState() {
    super.initState();
    approvedTrainers = fetchApprovedTrainers(); // เริ่มดึงข้อมูลตอนเริ่มต้น
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ครูมวยที่ได้รับการอนุมัติ'),
        backgroundColor: const Color.fromARGB(248, 226, 131, 53),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: approvedTrainers, // ใช้ FutureBuilder เพื่อแสดงข้อมูล
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('ยังไม่มีครูมวยที่ได้รับการอนุมัติ'));
          } else {
            // แสดงรายการครูมวยที่ได้รับการอนุมัติ
            final trainers = snapshot.data!;
            return ListView.builder(
              itemCount: trainers.length,
              itemBuilder: (context, index) {
                final trainer = trainers[index];
                return ListTile(
                  title: Text(trainer['fullname'] ?? 'ไม่มีชื่อ'),
                  subtitle: Text(trainer['username'] ?? 'ไม่มีชื่อผู้ใช้'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
