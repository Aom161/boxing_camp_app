import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:boxing_camp_app/variable.dart';

class BoxerTrainingPage extends StatefulWidget {
  final String boxerId;
  final String boxerName;
  final String accessToken;

  const BoxerTrainingPage({
    Key? key,
    required this.boxerId,
    required this.boxerName,
    required this.accessToken,
  }) : super(key: key);

  @override
  State<BoxerTrainingPage> createState() => _BoxerTrainingPageState();
}

class _BoxerTrainingPageState extends State<BoxerTrainingPage> {
  late String? username;
  late String? _id;
  late String accessToken;
  late SharedPreferences logindata;
  bool _isCheckingStatus = false;
  List<TrainingData> runningData = [];
  List<TrainingData> ropeJumpingData = [];
  List<TrainingData> punchingData = [];
  List<TrainingData> weightTrainingData = [];

  @override
  void initState() {
    super.initState();
    getInitialize();
    _fetchTrainingData();
  }

  void getInitialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckingStatus = prefs.getBool("isLoggedIn") ?? false;
      username = prefs.getString("username") ?? "ไม่ได้ลงชื่อเข้าใช้";
      accessToken = prefs.getString("accessToken") ?? "";
      _id = prefs.getString('_id');
    });
  }

  Future<void> _fetchTrainingData() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/gettrainingbyboxer/${widget.boxerId}'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> trainings = jsonDecode(response.body);
        setState(() {
          runningData.clear();
          ropeJumpingData.clear();
          punchingData.clear();
          weightTrainingData.clear();

          for (var training in trainings) {
            DateTime updatedAt = DateTime.parse(training['updated_at']);

            if (training['running'] != null) {
              double distance = training['running']['distance']?.toDouble() ??
                  0.0; // Default to 0.0 if null
              runningData.add(TrainingData(updatedAt, distance));
            }

            if (training['ropeJumping'] != null) {
              int count =
                  training['ropeJumping']['count'] ?? 0; // Default to 0 if null
              ropeJumpingData.add(TrainingData(updatedAt, count.toDouble()));
            }

            if (training['punching'] != null) {
              int count =
                  training['punching']['count'] ?? 0; // Default to 0 if null
              punchingData.add(TrainingData(updatedAt, count.toDouble()));
            }

            if (training['weightTraining'] != null) {
              int count = training['weightTraining']['count'] ??
                  0; // Default to 0 if null
              weightTrainingData.add(TrainingData(updatedAt, count.toDouble()));
            }
          }
        });
      } else {
        throw Exception('ไม่สามารถโหลดข้อมูลการฝึกได้');
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
        title: Text("การฝึกของ ${widget.boxerName}"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildTrainingChart('การวิ่ง (นาที)', runningData,
                yAxisTitle: 'ระยะทาง (กิโลเมตร)', interval: 5),
            buildTrainingChart('การกระโดดเชือก (นาที)', ropeJumpingData,
                yAxisTitle: 'จำนวนครั้ง', interval: 50),
            buildTrainingChart('การชกกระสอบทราย (นาที)', punchingData,
                yAxisTitle: 'จำนวนครั้ง', interval: 50),
            buildTrainingChart('การยกน้ำหนัก (นาที)', weightTrainingData,
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
