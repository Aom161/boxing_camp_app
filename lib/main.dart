import 'package:boxing_camp_app/firebase_options.dart';
import 'package:boxing_camp_app/page/addboxerpage.dart';
import 'package:boxing_camp_app/page/addboxingcamp.dart';
import 'package:boxing_camp_app/page/adminpage.dart';
import 'package:boxing_camp_app/page/boxerall.dart';
// import 'package:boxing_camp_app/page/appprovedtrainer.dart';
import 'package:boxing_camp_app/page/boxerpage.dart';
import 'package:boxing_camp_app/page/boxeruser.dart';
import 'package:boxing_camp_app/page/boxingcampuser.dart';
import 'package:boxing_camp_app/page/campdetail.dart';
import 'package:boxing_camp_app/page/contact.dart';
import 'package:boxing_camp_app/page/dashboard.dart';
import 'package:boxing_camp_app/page/dashboardmanager.dart';
import 'package:boxing_camp_app/page/dashboardtrainer.dart';
import 'package:boxing_camp_app/page/dashboarduser.dart';
import 'package:boxing_camp_app/page/editcamp.dart';
import 'package:boxing_camp_app/page/editprofile.dart';
import 'package:boxing_camp_app/page/firstpage.dart';
import 'package:boxing_camp_app/page/homepage.dart';
import 'package:boxing_camp_app/page/loginpage.dart';
import 'package:boxing_camp_app/page/managereditcamp.dart';
import 'package:boxing_camp_app/page/managerequestpage.dart';
import 'package:boxing_camp_app/page/managerequesttrainerpage.dart';
import 'package:boxing_camp_app/page/managerpage.dart';
import 'package:boxing_camp_app/page/managerprofile.dart';
import 'package:boxing_camp_app/page/managertrininghistory.dart';
import 'package:boxing_camp_app/page/manegeruser.dart';
import 'package:boxing_camp_app/page/mytraining.dart';
import 'package:boxing_camp_app/page/profilepage.dart';
import 'package:boxing_camp_app/page/requestpage.dart';
import 'package:boxing_camp_app/page/requestpagetrainer.dart';
import 'package:boxing_camp_app/page/showcamp.dart';
import 'package:boxing_camp_app/page/trainerpage.dart';
import 'package:boxing_camp_app/page/trainerprofilepage.dart';
import 'package:boxing_camp_app/page/traineruser.dart';
import 'package:boxing_camp_app/page/traininghistory.dart';
import 'package:boxing_camp_app/page/trainingpage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boxing_camp_app/page/onepage.dart';

import 'page/mycamp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else {
          String? role = snapshot.data;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Boxing Camp',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(253, 173, 53, 1),
                background: const Color.fromARGB(254, 214, 115, 1),
              ),
              useMaterial3: true,
            ),
            initialRoute: role == null ? '/home' : _getInitialRoute(role),
            routes: {
              '/home': (context) => const HomePage(),
              '/addCamp': (context) => const AddCampPage(),
              '/getcamp': (context) => CampsScreen(),
              '/addtraining': (context) => const ActivityFormPage(),
              '/profile': (context) => const ProfilePage(),
              '/trainerprofile': (context) => TrainerProfilePage(),
              '/managerprofile': (context) => ManagerProfilePage(),
              '/contact': (context) => const ContactPage(),
              '/login': (context) => const LoginScreen(),
              '/traininghistory': (context) => const ActivityHistoryPage(),
              '/adminpage': (context) => const AdminHomePage(),
              '/boxerpage': (context) => const Boxerpage(),
              '/dashboard': (context) => const DashboardPage(),
              '/editprofile': (context) => EditProfile(userData: const {}),
              '/firstpage': (context) => const Firstpage(),
              '/managerpage': (context) => const ManagerHomePage(),
              '/trainer': (context) => const TrainerHomePage(),
              '/addboxer': (context) => const AddBoxerPage(),
              '/campDetail': (context) => CampDetailScreen(camp: const {}),
              '/traineruser': (context) => const Traineruser(),
              '/boxeruser': (context) => const Boxeruser(),
              '/manegeruser': (context) => const Manegeruser(),
              '/onepage': (context) => const Onepage(),
              '/mycamp': (context) => MyCampsScreen(
                    manager: '',
                  ),
              '/editcamp': (context) => EditCampPage(
                    id: '',
                  ),
              '/dashboarduser': (context) => DashboardUser(),
              '/campforuser': (context) => CampUser(),
              '/mytraining': (context) => TrainingHistoryPage(),
              '/request': (context) => RequestToJoinCampPage(),
              '/approveordeny': (context) => ManageRequestsPage(),
              '/approveordenytrainer': (context) => ManageRequestsTrainerPage(),
              '/requesttrainer': (context) =>
                  RequestToJoinCampPageForTrainers(),
              '/managerhistory': (context) => ManagerActivityHistoryPage(),
              '/managereditcamp': (context) => ManagerEditCampPage(),
              '/dashboardtrainer': (context) => DashboardTrainerPage(),
              '/dashboardmanager': (context) => DashboardManagerPage(),
              '/boxerall':(context)=> BoxerAll(),

            },
            home: const LoginScreen(),
          );
        }
      },
    );
  }

  Future<String?> _getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  String _getInitialRoute(String role) {
    if (role == 'admin') return '/adminpage';
    if (role == 'manager') return '/managerpage';
    if (role == 'trainer') return '/trainer';
    if (role == 'boxer') return '/boxerpage';
    return '/home';
  }
}

class BaseAppDrawer extends StatefulWidget {
  final String? username;
  final String? role;
  final bool? isLoggedIn;
  final Function(BuildContext) onHomeTap;
  final Function(BuildContext) onCampTap;
  final Function(BuildContext) onContactTap;

  const BaseAppDrawer({
    super.key,
    this.username,
    this.role,
    this.isLoggedIn,
    required this.onHomeTap,
    required this.onCampTap,
    required this.onContactTap,
  });

  @override
  _BaseAppDrawerState createState() => _BaseAppDrawerState();
}

class _BaseAppDrawerState extends State<BaseAppDrawer> {
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('username');
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('role');
    await prefs.remove('_id');
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 0, 0, 0),
            ),
            child: Image.asset(
              'assets/images/logomuay.png',
              height: 100,
            ),
          ),
          
          if (widget.role! == '') ...[
            ListTile(
              title: const Text('หน้าแรก'),
              onTap: () {
                Navigator.pushNamed(context, '/home');
              },
            ),
            ListTile(
              title: const Text('แดชบอร์ด'),
              onTap: () {
                Navigator.pushNamed(context, '/dashboarduser');
              },
            ),
            ListTile(
              title: const Text('ค่ายมวยทั้งหมด'),
              onTap: () {
                Navigator.pushNamed(context, '/campforuser');
              },
            ),
            ListTile(
            title: const Text('ติดต่อเรา'),
            onTap: () => widget.onContactTap(context),
            ),
          ],



          if (widget.role! == "ผู้ดูแลระบบ") ...[
            ListTile(
              title: const Text('แดชบอร์ด'),
              onTap: () {
                Navigator.pushNamed(context, '/dashboard');
              },
            ),
            ListTile(
              title: const Text('นักมวยทั้งหมด'),
              onTap: () {
                Navigator.pushNamed(context, '/boxeruser');
              },
            ),
            ListTile(
              title: const Text('ผู้จัดการค่ายมวย'),
              onTap: () {
                Navigator.pushNamed(context, '/manegeruser');
              },
            ),
            ListTile(
              title: const Text('ครูมวยทั้งหมด'),
              onTap: () {
                Navigator.pushNamed(context, '/traineruser');
              },
            ),
            ListTile(
              title: const Text('ค่ายมวยทั้งหมด'),
              onTap: () {
                Navigator.pushNamed(context, '/getcamp');
              },
            ),
            ListTile(
              title: const Text('จัดการค่าย'),
              onTap: () {
                Navigator.pushNamed(context, '/editcamp');
              },
            ),
          ],



          if (widget.role! == "ผู้จัดการค่ายมวย") ...[
            ListTile(
              title: const Text('หน้าเเรก'),
              onTap: () {
                Navigator.pushNamed(context, '/onepage');
              },
            ),
            ListTile(
              title: const Text('โปรไฟล์'),
              onTap: () {
                Navigator.pushNamed(context, '/managerprofile');
              },
            ),
            ListTile(
              title: const Text('คำขอนักมวย'),
              onTap: () {
                Navigator.pushNamed(context, '/approveordeny');
              },
            ),
            ListTile(
              title: const Text('คำขอครูมวย'),
              onTap: () {
                Navigator.pushNamed(context, '/approveordenytrainer');
              },
            ),
            ListTile(
              title: const Text('ค่ายมวยของฉัน'),
              onTap: () {
                Navigator.pushNamed(context, '/mycamp');
              },
            ),
            ListTile(
              title: const Text('จัดการค่ายมวยของตัวเอง'),
              onTap: () {
                Navigator.pushNamed(context, '/managereditcamp');
              },
            ),
            ListTile(
              title: const Text('นักมวยทั้งหมด'),
              onTap: () {
                Navigator.pushNamed(context, '/boxerall');
              },
            ),
            ListTile(
              title: const Text('ค่ายมวยทั้งหมด'),
              onTap: () {
                Navigator.pushNamed(context, '/getcamp');
              },
            ),
            ListTile(
              title: const Text('แดชบอร์ด'),
              onTap: () {
                Navigator.pushNamed(context, '/dashboardmanager');
              },
            ),
            ListTile(
              title: const Text('ประวัติการฝึกซ้อม'),
              onTap: () {
                Navigator.pushNamed(context, '/managerhistory');
              },
            ),
          ],



          if (widget.role! == "นักมวย") ...[
            ListTile(
              title: const Text('หน้าเเรก'),
              onTap: () {
                Navigator.pushNamed(context, '/boxerpage');
              },
            ),
            ListTile(
              title: const Text('โปรไฟล์'),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              title: const Text('ส่งคำขอค่าย'),
              onTap: () {
                Navigator.pushNamed(context, '/request');
              },
            ),
            ListTile(
              title: const Text('ประวัติการฝึกซ้อม'),
              onTap: () {
                Navigator.pushNamed(context, '/mytraining');
              },
            ),
            ListTile(
              title: const Text('แดชบอร์ด'),
              onTap: () {
                Navigator.pushNamed(context, '/dashboard');
              },
            ),
            ListTile(
              title: const Text('ค่ายมวยทั้งหมด'),
              onTap: () {
                Navigator.pushNamed(context, '/campforuser');
              },
            ),
          ],


          if (widget.role! == "ครูมวย") ...[
            ListTile(
              title: const Text('หน้าเเรก'),
              onTap: () {
                Navigator.pushNamed(context, '/onepage');
              },
            ),
            
            ListTile(
              title: const Text('โปรไฟล์'),
              onTap: () {
                Navigator.pushNamed(context, '/trainerprofile');
              },
            ),
            ListTile(
              title: const Text('ส่งคำขอค่าย'),
              onTap: () {
                Navigator.pushNamed(context, '/requesttrainer');
              },
            ),
            ListTile(
              title: const Text('เพิ่มการฝึก'),
              onTap: () {
                Navigator.pushNamed(context, '/addtraining');
              },
            ),
            ListTile(
              title: const Text('แดชบอร์ด'),
              onTap: () {
                Navigator.pushNamed(context, '/dashboardtrainer');
              },
            ),
            ListTile(
              title: const Text('ประวัติการฝึกซ้อม'),
              onTap: () {
                Navigator.pushNamed(context, '/traininghistory');
              },
            ),
            ListTile(
              title: const Text('ค่ายมวยทั้งหมด'),
              onTap: () {
                Navigator.pushNamed(context, '/campforuser');
              },
            ),
            ListTile(
              title: const Text('นักมวยทั้งหมด'),
              onTap: () {
                Navigator.pushNamed(context, '/boxerall');
              },
            ),
            
            ListTile(
            title: const Text('ติดต่อเรา'),
            onTap: () => widget.onContactTap(context),
            ),
          ],

          ListTile(
            title: widget.isLoggedIn!
                ? OutlinedButton(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.red,
                        width: 3,
                      ),
                    ),
                    child: const Text(
                      "ออกจากระบบ",
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 16,
                      ),
                    ),
                  )
                : OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.green,
                        width: 3,
                      ),
                    ),
                    child: const Text(
                      "เข้าสู่ระบบ",
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
