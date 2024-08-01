import 'package:flutter/material.dart';
import 'package:resecure_camera/camera_nav.dart';
import 'package:resecure_camera/people_nav.dart';
import 'package:resecure_camera/recording_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _widgetOptions() => <Widget>[
        const RecordingsPage(),
        const CameraPage(),
        const PeoplePage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'ReSecure Camera',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _widgetOptions().elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2C3E50),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Recordings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Viewers',
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
