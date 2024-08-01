import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:resecure_camera/add_viewer.dart';
import 'firebase_data_service.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  List<Map<dynamic, dynamic>> _people = [];
  String cameraId = "";
  FirebaseDataService firebaseDataService =
      FirebaseDataService(); // Set the actual camera ID here
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setCameraId().then((_) => _fetchPeople());
  }

  Future<void> _setCameraId() async {
    cameraId = await firebaseDataService.getDeviceIdentifier();
  }

  Future<void> _fetchPeople() async {
    final firebaseDataService = FirebaseDataService();
    List<Map<dynamic, dynamic>> people =
        await firebaseDataService.fetchCameraAccessByCameraId(cameraId);

    setState(() {
      _people = people;
      _isLoading = false;
    });
  }

  Future<void> _removeUser(String userId) async {
    final cameraAccessRef = FirebaseDatabase.instance
        .ref()
        .child('camera_access')
        .child('${cameraId}_$userId');
    try {
      await cameraAccessRef.remove();
      setState(() {
        _people.removeWhere((person) => person['user_id'] == userId);
      });
    } catch (e) {
      print('Error removing user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const SizedBox(
                  height: 40,
                  child: Center(
                    child: Text(
                      'CONNECTED USERS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _people.length,
                    itemBuilder: (context, index) {
                      final person = _people[index];
                      return Card(
                        color: const Color(0xFFD9D9D9),
                        margin: const EdgeInsets.all(10.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side:
                              const BorderSide(color: Colors.black, width: 1.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 15.0),
                          title: Text(
                            person['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${person['email']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                'Permissions: ${_buildPermissionsText(person)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeUser(person['user_id']),
                                iconSize: 40,
                                color: const Color(0xFFBC2222),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddViewer()),
          );
        },
        backgroundColor: const Color(0xFFD9D9D9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
        child: const Icon(
          Icons.person_add,
          size: 30,
          color: Colors.black,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  String _buildPermissionsText(Map<dynamic, dynamic> person) {
    List<String> permissions = [];

    if (person['is_admin'] == true) {
      permissions.add('Admin');
    } else {
      if (person['view_live'] == true) {
        permissions.add('View Live');
      }
      if (person['camera_settings'] == true) {
        permissions.add('Change Camera Settings');
      }
      if (person['view_recordings'] == true) {
        permissions.add('View Recordings');
      }
    }

    return permissions.join(', ');
  }
}
