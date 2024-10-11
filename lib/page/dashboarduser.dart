import 'dart:convert';
import 'package:boxing_camp_app/main.dart';
import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DashboardUser extends StatefulWidget {
  const DashboardUser({super.key});

  @override
  State<DashboardUser> createState() => _DashboardUserState();
}

class _DashboardUserState extends State<DashboardUser> {

  List<TrainingData> runningData = [];
  List<TrainingData> ropeJumpingData = [];
  List<TrainingData> punchingData = [];
  List<TrainingData> weightTrainingData = [];

  @override
  void initState() {
    super.initState();
    _fetchTrainingData();
  }

  Future<void> _fetchTrainingData() async {
    try {
      final response =
          await http.get(Uri.parse('$apiUrl/gettrainingall'));

      if (response.statusCode == 200) {
        final List<dynamic> trainings = jsonDecode(response.body);
        print('Training data: $trainings'); // ตรวจสอบข้อมูลที่ได้รับ

        setState(() {
          runningData.clear();
          ropeJumpingData.clear();
          punchingData.clear();
          weightTrainingData.clear();

          for (var training in trainings) {
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
              weightTrainingData.add(TrainingData(updatedAt, count.toDouble()));
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

  Widget buildTrainingChart(String title, List<TrainingData> data) {
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
          title: AxisTitle(text: 'Date'),
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: 'Count / Distance'),
          minimum: 0,
          interval: 5, // Increase values every 5 units
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
      ),
      drawer: BaseAppDrawer(
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
            buildTrainingChart('Running Duration (Minutes)', runningData),
            buildTrainingChart(
                'Rope Jumping Duration (Minutes)', ropeJumpingData),
            buildTrainingChart('Punching Duration (Minutes)', punchingData),
            buildTrainingChart(
                'Weight Training Duration (Minutes)', weightTrainingData),
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
