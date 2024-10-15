import 'dart:convert';
import 'package:boxing_camp_app/main.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DashboardTrainerPage extends StatefulWidget {
  final String? username;
  const DashboardTrainerPage({super.key, this.username});

  @override
  State<DashboardTrainerPage> createState() => _DashboardTrainerPageState();
}

class _DashboardTrainerPageState extends State<DashboardTrainerPage> {
  late String? username;
  late String? _id;
  String accessToken = "";
  String refreshToken = "";
  String role = "";
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;
  List<TrainingData> runningData = [];
  List<TrainingData> ropeJumpingData = [];
  List<TrainingData> punchingData = [];
  List<TrainingData> weightTrainingData = [];

  @override
  void initState() {
    super.initState();
    username = widget.username;
    getInitialize();
    _fetchTrainingData();
  }

  void getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn") ?? false;
      username = prefs.getString("username") ?? "ไม่ได้ลงชื่อเข้าใช้";
      accessToken = prefs.getString("accessToken") ?? "";
      refreshToken = prefs.getString("refreshToken") ?? "";
      role = prefs.getString("role") ?? "No Role";
      _id = prefs.getString('_id');
    });

    print(_isCheckingStatus);
    print(username);
    print(accessToken);
    print(refreshToken);
    print(role);
  }

  Future<void> _fetchTrainingData() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/gettrainingall'));

      if (response.statusCode == 200) {
        final List<dynamic> trainings = jsonDecode(response.body);
        print('Training data: $trainings'); // ตรวจสอบข้อมูลที่ได้รับ

        setState(() {
          runningData.clear();
          ropeJumpingData.clear();
          punchingData.clear();
          weightTrainingData.clear();

          for (var training in trainings) {
            // ตรวจสอบว่า boxerId ตรงกับ _id ของผู้ใช้หรือไม่
            if (training['userId'] == _id) {
              // Process running data
              if (training['running'] != null) {
                DateTime updatedAt = DateTime.parse(training['updated_at']);
                double distance = training['running']['distance'].toDouble();
                runningData.add(TrainingData(updatedAt, distance));
              }

              // Process rope jumping data
              if (training['ropeJumping'] != null &&
                  training['ropeJumping']['count'] != null) {
                DateTime updatedAt = DateTime.parse(training['updated_at']);
                int count = training['ropeJumping']['count'];
                ropeJumpingData.add(TrainingData(updatedAt, count.toDouble()));
              }

              // Process punching data
              if (training['punching'] != null &&
                  training['punching']['count'] != null) {
                DateTime updatedAt = DateTime.parse(training['updated_at']);
                int count = training['punching']['count'];
                punchingData.add(TrainingData(updatedAt, count.toDouble()));
              }

              // Process weight training data
              if (training['weightTraining'] != null &&
                  training['weightTraining']['count'] != null) {
                DateTime updatedAt = DateTime.parse(training['updated_at']);
                int count = training['weightTraining']['count'];
                weightTrainingData
                    .add(TrainingData(updatedAt, count.toDouble()));
              }
            }
          }
        });
      } else {
        throw Exception('Failed to load training data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget buildTrainingChart(String title, List<TrainingData> data,
      {String yAxisTitle = 'Duration', double interval = 5}) {
    // Create a map to group training data by date
    Map<DateTime, double> groupedData = {};

    // Loop through the training data and group it by date
    for (var training in data) {
      DateTime date =
          DateTime(training.date.year, training.date.month, training.date.day);
      if (groupedData.containsKey(date)) {
        groupedData[date] =
            groupedData[date]! + training.duration; // Sum duration or count
      } else {
        groupedData[date] =
            training.duration; // Initialize with the duration/count
      }
    }

    // Convert grouped data to a list of TrainingData
    List<TrainingData> chartData = groupedData.entries
        .map((entry) =>
            TrainingData(entry.key, entry.value)) // Create TrainingData objects
        .toList();

    // Create Padding and SfCartesianChart
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          interval: 1, // Show every day
          intervalType: DateTimeIntervalType.days, // Day interval type
          dateFormat: DateFormat('E'), // Format date to show day names
          title: AxisTitle(text: 'วัน'),
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: yAxisTitle), // Dynamic title for Y axis
          interval: interval, // Dynamic interval for Y axis
        ),
        title: ChartTitle(text: title),
        series: <CartesianSeries>[
          ColumnSeries<TrainingData, DateTime>(
            dataSource: chartData,
            xValueMapper: (TrainingData training, _) => training.date,
            yValueMapper: (TrainingData training, _) => training.duration,
            dataLabelMapper: (TrainingData training, _) =>
                training.duration.toString(), // Show the value on the bar
            dataLabelSettings: DataLabelSettings(isVisible: true),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "แดชบอร์ด",
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildTrainingChart('การวิ่ง ', runningData,
                yAxisTitle: 'ระยะทาง (กิโลเมตร)', interval: 5),
            buildTrainingChart('การกระโดดเชือก ', ropeJumpingData,
                yAxisTitle: 'จำนวนครั้ง', interval: 50),
            buildTrainingChart('การชกกระสอบทราย ', punchingData,
                yAxisTitle: 'จำนวนครั้ง', interval: 50),
            buildTrainingChart('การยกน้ำหนัก ', weightTrainingData,
                yAxisTitle: 'จำนวนครั้ง', interval: 10),
          ],
        ),
      ),
    );
  }
}

class TrainingData {
  TrainingData(this.date, this.duration);
  final DateTime date;
  final double duration;
}
