import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:resecure_user/camera_nav.dart';
import 'package:resecure_user/local_notification_service.dart';
import 'package:resecure_user/profile_page.dart';
import 'package:resecure_user/guid_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  @override
  void initState(){
    super.initState();
    _notifications();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _notifications() async {
    print("Dbg Here");
    final dbRef = FirebaseDatabase.instance;
    final userRef = FirebaseAuth.instance.currentUser;
    String? user_id = userRef?.uid;
    final List<String> cameraIds = [];
    final List<String> ownerUserIds = [];
    final notify = LocalNotificationService();
    final processedIds = <String>{};

    final cameraAccessSnapshot = await dbRef.ref().child('camera_access')
        .orderByChild('user_id')
        .equalTo(user_id)
        .once();

    if (cameraAccessSnapshot.snapshot.value != null) {
      final camerasData =
      cameraAccessSnapshot.snapshot.value as Map<dynamic, dynamic>;
      for (var cameraAccess in camerasData.values) {
        if (cameraAccess['is_invitation_accepted'] == true) {
          cameraIds.add(cameraAccess['camera_id']);
          ownerUserIds.add(cameraAccess['owner_user_id']);
        }
      }
    }

    final recordingsRef = dbRef.ref().child('recordings');

    recordingsRef.onChildAdded.listen((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final entryId = event.snapshot.key;
      int i = cameraIds.indexOf(data["camera_id"]);
      if (i != -1 && !processedIds.contains(entryId)) {
        processedIds.add(entryId!);

        final cameraSnapshot = await dbRef.ref().child("cameras").child(ownerUserIds[i])
            .orderByChild("device_identifier")
            .equalTo(data["camera_id"])
            .once();
        if (cameraSnapshot.snapshot.value != null) {
          final cameraData = cameraSnapshot.snapshot.value as Map<dynamic, dynamic>;
          final cameraName = cameraData.values.first['name'];
          notify.showNotificationAndroid(
              "Motion Detected",
              "Motion detected by camera: $cameraName"
          );
        }
      }
    });
  }

  List<Widget> _widgetOptions() => <Widget>[
        const GuidPage(),
        const CameraListPage(),
        const ProfilePage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'ReSecure',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _widgetOptions().elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2C3E50),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.question_answer_rounded),
            label: 'Help',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Cameras',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        unselectedItemColor: Colors.white,
        selectedItemColor: const Color(0xFF00FF57),
        onTap: _onItemTapped,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedIconTheme: const IconThemeData(color: Color(0xFF00FF57)),
        unselectedIconTheme: const IconThemeData(color: Colors.white),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        iconSize: 30,
      ),
    );
  }
}
