import 'package:boxing_camp_app/main.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ActivityFormPage extends StatefulWidget {
  final String? username;

  const ActivityFormPage({super.key, this.username});
  @override
  _ActivityFormPageState createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends State<ActivityFormPage> {
  late String? username;
  String accessToken = "";
  String refreshToken = "";
  String role = "";
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;
  String? selectedBoxer;
  List<Map<String, dynamic>> boxers = [];

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    username = widget.username;
    getInitialize();
    _fetchBoxers();
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

    String? lastActivityDate = prefs.getString("lastActivityDate");
    if (lastActivityDate != null) {
      DateTime lastDate = DateTime.parse(lastActivityDate);
      DateTime today = DateTime.now();

      if (lastDate.year == today.year &&
          lastDate.month == today.month &&
          lastDate.day == today.day) {}
    }

    print(_isCheckingStatus);
    print(username);
    print(accessToken);
    print(refreshToken);
    print(role);
  }

  Future<void> _fetchBoxers() async {
    final url = Uri.parse('$apiUrl/users');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> boxerList = jsonDecode(response.body);
        setState(() {
          // Include both fullname and _id
          boxers = boxerList
              .where((boxer) => boxer['role'] == 'นักมวย')
              .map((boxer) => {'id': boxer['_id'], 'name': boxer['fullname']})
              .toList();
        });
      } else {
        print('Failed to fetch boxers. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching boxers: $error');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  final TextEditingController runningDistanceController =
      TextEditingController();

  final TextEditingController ropeJumpingCountController =
      TextEditingController();
  final TextEditingController punchingCountController = TextEditingController();
  final TextEditingController weightTrainingCountController =
      TextEditingController();

  DateTime? runningStartTime;
  DateTime? runningEndTime;
  int runningDuration = 0;

  DateTime? ropeJumpingStartTime;
  DateTime? ropeJumpingEndTime;
  int ropeJumpingDuration = 0;

  DateTime? punchingStartTime;
  DateTime? punchingEndTime;
  int punchingDuration = 0;

  DateTime? weightTrainingStartTime;
  DateTime? weightTrainingEndTime;
  int weightTrainingDuration = 0;

  Future<void> _selectTime(BuildContext context, DateTime? initialTime,
      Function(DateTime) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime != null
          ? TimeOfDay.fromDateTime(initialTime)
          : TimeOfDay.now(),
    );
    if (picked != null) {
      onTimeSelected(DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        picked.hour,
        picked.minute,
      ));
    }
  }

  void _calculateDuration(
      DateTime? startTime, DateTime? endTime, Function(int) setDuration) {
    if (startTime != null && endTime != null) {
      if (endTime.isAfter(startTime)) {
        final duration = endTime.difference(startTime).inMinutes;

        if (duration >= 60) {
          // หากเวลารวมเท่ากับหรือมากกว่า 60 นาที จะคำนวณเป็นชั่วโมง
          setDuration(duration ~/ 60); // แปลงเป็นชั่วโมง
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ระยะเวลาซ้อมรวมคือ ${duration ~/ 60} ชั่วโมง'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setDuration(duration);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เวลาสิ้นสุดต้องมากกว่าเวลาเริ่มต้น'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> submitActivity() async {
    final runningDistance =
        double.tryParse(runningDistanceController.text) ?? 0.0;
    final ropeJumpingCount = int.tryParse(ropeJumpingCountController.text) ?? 0;
    final punchingCount = int.tryParse(punchingCountController.text) ?? 0;
    final weightTrainingCount =
        int.tryParse(weightTrainingCountController.text) ?? 0;

    final activityData = {
      'date': selectedDate.toIso8601String(),
      'username': username,
      'boxerId': selectedBoxer,
      'running': {
        'start_time': runningStartTime?.toIso8601String(),
        'end_time': runningEndTime?.toIso8601String(),
        'duration': runningDuration,
        'distance': runningDistance,
      },
      'ropeJumping': {
        'start_time': ropeJumpingStartTime?.toIso8601String(),
        'end_time': ropeJumpingEndTime?.toIso8601String(),
        'duration': ropeJumpingDuration,
        'count': ropeJumpingCount,
      },
      'punching': {
        'start_time': punchingStartTime?.toIso8601String(),
        'end_time': punchingEndTime?.toIso8601String(),
        'duration': punchingDuration,
        'count': punchingCount,
      },
      'weightTraining': {
        'start_time': weightTrainingStartTime?.toIso8601String(),
        'end_time': weightTrainingEndTime?.toIso8601String(),
        'duration': weightTrainingDuration,
        'count': weightTrainingCount,
      }
    };

    // ตรวจสอบว่ากำลังบันทึกข้อมูลย้อนหลังหรือไม่
    DateTime today = DateTime.now();
    if (selectedDate.year != today.year ||
        selectedDate.month != today.month ||
        selectedDate.day != today.day) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถบันทึกข้อมูลย้อนหลังได้'),
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
        ),
      );
      return;
    }

    final url = Uri.parse('$apiUrl/addtraining');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(activityData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกกิจกรรมสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('lastActivityDate', DateTime.now().toIso8601String());
      } else {
        print('submit training data. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      print('Error submitting training data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'บันทึกกิจกรรมรายวัน',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: ListTile(
                title: Text(
                  'วันที่บันทึก: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                  style: const TextStyle(fontSize: 18),
                ),
                trailing: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              hint: const Text("เลือกนักมวย"),
              value:
                  selectedBoxer, // This will store the ObjectId (not the name)
              onChanged: (String? newValue) {
                setState(() {
                  selectedBoxer =
                      newValue; // Store the ObjectId of the selected boxer
                });
              },
              items: boxers.map<DropdownMenuItem<String>>((boxer) {
                return DropdownMenuItem<String>(
                  value: boxer['id'], // Store the ObjectId here
                  child: Text(boxer['name']), // Display the boxer's name
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _buildActivityForm(
              context,
              title: 'วิ่ง',
              startTime: runningStartTime,
              endTime: runningEndTime,
              duration: runningDuration,
              onSelectStartTime: (time) {
                setState(() {
                  runningStartTime = time;
                  _calculateDuration(runningStartTime, runningEndTime,
                      (d) => runningDuration = d);
                });
              },
              onSelectEndTime: (time) {
                setState(() {
                  runningEndTime = time;
                  _calculateDuration(runningStartTime, runningEndTime,
                      (d) => runningDuration = d);
                });
              },
              distanceController: runningDistanceController,
            ),
            const SizedBox(height: 16),
            _buildActivityFormWithCount(
              context,
              title: 'กระโดดเชือก',
              startTime: ropeJumpingStartTime,
              endTime: ropeJumpingEndTime,
              duration: ropeJumpingDuration,
              countController: ropeJumpingCountController,
              onSelectStartTime: (time) {
                setState(() {
                  ropeJumpingStartTime = time;
                  _calculateDuration(ropeJumpingStartTime, ropeJumpingEndTime,
                      (d) => ropeJumpingDuration = d);
                });
              },
              onSelectEndTime: (time) {
                setState(() {
                  ropeJumpingEndTime = time;
                  _calculateDuration(ropeJumpingStartTime, ropeJumpingEndTime,
                      (d) => ropeJumpingDuration = d);
                });
              },
            ),
            const SizedBox(height: 16),
            _buildActivityFormWithCount(
              context,
              title: 'การชกกระสอบทราย',
              startTime: punchingStartTime,
              endTime: punchingEndTime,
              duration: punchingDuration,
              countController: punchingCountController,
              onSelectStartTime: (time) {
                setState(() {
                  punchingStartTime = time;
                  _calculateDuration(punchingStartTime, punchingEndTime,
                      (d) => punchingDuration = d);
                });
              },
              onSelectEndTime: (time) {
                setState(() {
                  punchingEndTime = time;
                  _calculateDuration(punchingStartTime, punchingEndTime,
                      (d) => punchingDuration = d);
                });
              },
            ),
            const SizedBox(height: 16),
            _buildActivityFormWithCount(
              context,
              title: 'ยกน้ำหนัก',
              startTime: weightTrainingStartTime,
              endTime: weightTrainingEndTime,
              duration: weightTrainingDuration,
              countController: weightTrainingCountController,
              onSelectStartTime: (time) {
                setState(() {
                  weightTrainingStartTime = time;
                  _calculateDuration(weightTrainingStartTime,
                      weightTrainingEndTime, (d) => weightTrainingDuration = d);
                });
              },
              onSelectEndTime: (time) {
                setState(() {
                  weightTrainingEndTime = time;
                  _calculateDuration(weightTrainingStartTime,
                      weightTrainingEndTime, (d) => weightTrainingDuration = d);
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: submitActivity,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 97, 203, 5),
              ),
              child: const Text(
                'บันทึกกิจกรรม',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActivityForm(
    BuildContext context, {
    required String title,
    required DateTime? startTime,
    required DateTime? endTime,
    required int duration,
    required Function(DateTime) onSelectStartTime,
    required Function(DateTime) onSelectEndTime,
    TextEditingController? distanceController,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: Text(
                  'เวลาเริ่มซ้อม: ${startTime != null ? DateFormat('HH:mm').format(startTime) : 'ยังไม่ได้เลือกเวลา'}'),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(context, startTime, onSelectStartTime),
            ),
            ListTile(
              title: Text(
                  'เวลาสิ้นสุดการซ้อม: ${endTime != null ? DateFormat('HH:mm').format(endTime) : 'ยังไม่ได้เลือกเวลา'}'),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(context, endTime, onSelectEndTime),
            ),
            const SizedBox(height: 8),
            if (distanceController != null)
              TextField(
                controller: distanceController,
                decoration: const InputDecoration(
                  labelText: 'ระยะทาง (กิโลเมตร)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 8),
            Text(
              'ระยะเวลาที่ซ้อม: $duration นาที',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFormWithCount(
    BuildContext context, {
    required String title,
    required DateTime? startTime,
    required DateTime? endTime,
    required int duration,
    required TextEditingController countController,
    required Function(DateTime) onSelectStartTime,
    required Function(DateTime) onSelectEndTime,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: Text(
                  'เวลาเริ่มซ้อม: ${startTime != null ? DateFormat('HH:mm').format(startTime) : 'ยังไม่ได้เลือกเวลา'}'),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(context, startTime, onSelectStartTime),
            ),
            ListTile(
              title: Text(
                  'เวลาสิ้นสุดการซ้อม: ${endTime != null ? DateFormat('HH:mm').format(endTime) : 'ยังไม่ได้เลือกเวลา'}'),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(context, endTime, onSelectEndTime),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: countController,
              decoration: const InputDecoration(
                labelText: 'จำนวนครั้งที่ทำได้',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text(
              'ระยะเวลาที่ซ้อม: $duration นาที',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
