import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:resecure_user/local_notification_service.dart';
import 'package:resecure_user/new_invites_page.dart';
import 'package:resecure_user/user_access.dart';
import 'camera_view.dart';
import 'recording_nav.dart';
import 'add_camera.dart';
// import 'package:firebase_core/firebase_core.dart';

class CameraListPage extends StatefulWidget {
  const CameraListPage({super.key});

  @override
  State<CameraListPage> createState() => _CameraListPageState();
}

class _CameraListPageState extends State<CameraListPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _cameraAccessRef =
      FirebaseDatabase.instance.ref().child('camera_access');
  final DatabaseReference _camerasRef =
      FirebaseDatabase.instance.ref().child('cameras');
  List<Map<dynamic, dynamic>> _cameras = [];
  List<Map<dynamic, dynamic>> _filteredCameras = [];
  late String userId;

  @override
  void initState() {
    super.initState();
    _fetchCameras();
  }

  Future<void> _fetchCameras() async {
    final user = _auth.currentUser;

    if (user != null) {
      userId = user.uid;

      final cameraAccessSnapshot = await _cameraAccessRef
          .orderByChild('user_id')
          .equalTo(user.uid)
          .once();

      if (cameraAccessSnapshot.snapshot.value != null) {
        final camerasData =
            cameraAccessSnapshot.snapshot.value as Map<dynamic, dynamic>;
        final List<Map<dynamic, dynamic>> cameras = [];

        for (var cameraAccess in camerasData.values) {
          if (cameraAccess['is_invitation_accepted'] == true) {
            final cameraId = cameraAccess['camera_id'];
            final cameraSnapshot = await _camerasRef
                .child(cameraAccess["owner_user_id"])
                .child(cameraId)
                .once();

            if (cameraSnapshot.snapshot.value != null) {
              final camera =
                  cameraSnapshot.snapshot.value as Map<dynamic, dynamic>;
              cameras.add({
                'camera_id': cameraId,
                'camera_name': camera['name'],
                'is_active': camera['is_active'],
                'is_admin': cameraAccess['is_admin'],
                'view_live': cameraAccess['view_live'],
                'view_recordings': cameraAccess['view_recordings'],
                'owner_user_id': cameraAccess['owner_user_id']
              });
            }
          }
        }

        setState(() {
          _cameras = cameras;
          _filteredCameras = cameras;
        });
      }
    }
  }

  void _filterCameras(String query) {
    final filteredCameras = _cameras.where((camera) {
      final cameraName = camera['camera_name'] as String;
      return cameraName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredCameras = filteredCameras;
    });
  }

  void _newInvites() {
    final user = _auth.currentUser;

    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewInvitesPage(userId: user.uid),
        ),
      );
    }
    print('Dbg New Invites');
  }

  void _viewLive(String cameraId, String cameraUserId) async{
    final cameraRef = FirebaseDatabase.instance
        .ref()
        .child('cameras')
        .child(cameraUserId)
        .child(cameraId);
    await cameraRef.update({"user_connected": true});
    sleep(const Duration(seconds: 3));
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CameraViewPage(
                cameraId: cameraId,
                cameraUserId: cameraUserId,
              )),
    );
    print('Dbg View Live');
  }

  void _viewRecordings(String cameraId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RecordingsPage(cameraId: cameraId)),
    );
    print('Dbg View Recordings');
  }

  Future<void> _userAccess(String cameraId, String ownerUserId) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UserAccessPage(cameraId: cameraId, currentUserId: userId, ownerUserId: ownerUserId),
      ),
    );

    print('Dbg User Access');
  }

  Future<void> _removeCamera(String cameraId) async {
    final cameraAccessRef = _cameraAccessRef.child("${cameraId}_$userId");
    try {
      await cameraAccessRef.remove();
      setState(() {
        _filteredCameras
            .removeWhere((camera) => camera['camera_id'] == cameraId);
      });
    } catch (e) {
      print('Error removing user: $e');
    }
    print('Dbg Remove Camera: $cameraId, userId: $userId');
  }

  void _addCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCameraPage()),
    );
    print('Dbg Add Camera');
    // Add your add camera functionality here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterCameras,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Camera name',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _newInvites,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C3E50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            5.0), // Adjust this value to reduce curvature
                      ),
                    ),
                    child: const Text(
                      'New Invites',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCameras.length,
                itemBuilder: (context, index) {
                  final camera = _filteredCameras[index];
                  print("Dbg camera $camera");
                  final cameraName = camera['camera_name'] as String;
                  final isActive = camera['is_active'] as bool;
                  final isAdmin = camera['is_admin'] as bool;
                  final viewLive = camera['view_live'] as bool;
                  final viewRecordings = camera['view_recordings'] as bool;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: const BorderSide(color: Colors.black, width: 1.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Camera Name: $cameraName',
                                  style: const TextStyle(fontSize: 12.0),
                                ),
                              ),
                              Container(
                                width: 20.0,
                                height: 20.0,
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5.0),
                          Text(
                            'Access: ${_buildPermissionsText(camera)}',
                            style: const TextStyle(fontSize: 12.0),
                          ),
                          const SizedBox(height: 5.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (viewLive)
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.videocam,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _viewLive(
                                          camera['camera_id'],
                                          camera['owner_user_id']),
                                    ),
                                    const Text(
                                      'View Live',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              if (viewRecordings)
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.video_library,
                                          color: Colors.grey),
                                      onPressed: () => _viewRecordings(camera['camera_id']),
                                    ),
                                    const Text(
                                      'Recordings',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              if (isAdmin)
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.person,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _userAccess(camera['camera_id'], camera['owner_user_id']),
                                    ),
                                    const Text(
                                      'User Access',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _removeCamera(camera['camera_id']),
                                  ),
                                  const Text(
                                    'Remove',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCamera,
        tooltip: 'Add Camera',
        backgroundColor: const Color(0xFFD9D9D9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
        child: const Icon(
          Icons.add_a_photo,
          size: 30,
          color: Colors.black,
        ),
      ),
    );
  }

  String _buildPermissionsText(Map<dynamic, dynamic> cameraAccess) {
    List<String> permissions = [];

    if (cameraAccess['is_admin'] == true) {
      permissions.add('Admin');
    } else {
      if (cameraAccess['view_live'] == true) {
        permissions.add('View Live');
      }
      if (cameraAccess['camera_settings'] == true) {
        permissions.add('Change Camera Settings');
      }
      if (cameraAccess['view_recordings'] == true) {
        permissions.add('View Recordings');
      }
    }

    return permissions.join(', ');
  }
}
