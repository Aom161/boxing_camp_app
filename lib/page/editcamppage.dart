import 'dart:convert';
import 'package:boxing_camp_app/variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditPage extends StatefulWidget {
  final String id;

  const EditPage({Key? key, required this.id}) : super(key: key);

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late String name;
  late String description;
  late double latitude;
  late double longitude;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchCampData();
  }

  Future<void> _fetchCampData() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/getcamp/${widget.id}'));
      if (response.statusCode == 200) {
        final camp = jsonDecode(response.body);
        setState(() {
          name = camp['name'];
          description = camp['description'];
          latitude = camp['location']['latitude'];
          longitude = camp['location']['longitude'];
        });
      } else {
        throw Exception('Failed to load camp data');
      }
    } catch (error) {
      print('Error fetching camp data: $error');
    }
  }

  Future<void> _editCamp() async {
    if (_formKey.currentState!.validate()) {
      // การส่งข้อมูลแก้ไขค่าย
      Map<String, dynamic> campData = {
        'name': name,
        'description': description,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
      };

      try {
        final response = await http.put(
          Uri.parse('$apiUrl/editcamp/${widget.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(campData),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Camp updated successfully!')));
          Navigator.pop(context); // กลับไปยังหน้าก่อนหน้า
        } else {
          throw Exception('Failed to edit camp');
        }
      } catch (error) {
        print('Error updating camp: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Camp'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(labelText: 'Camp Name'),
                onChanged: (value) {
                  setState(() {
                    name = value;
                  });
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter camp name';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: description,
                decoration: InputDecoration(labelText: 'Description'),
                onChanged: (value) {
                  setState(() {
                    description = value;
                  });
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              // แสดงฟิลด์สำหรับ latitude และ longitude หากต้องการ
              TextFormField(
                initialValue: latitude.toString(),
                decoration: InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    latitude = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              TextFormField(
                initialValue: longitude.toString(),
                decoration: InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    longitude = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _editCamp,
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
