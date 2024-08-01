import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'add_viewer.dart';

class UserAccessPage extends StatefulWidget {
  final String cameraId;
  final String currentUserId;
  final String ownerUserId;

  const UserAccessPage(
      {super.key, required this.cameraId, required this.currentUserId, required this.ownerUserId});

  @override
  State<UserAccessPage> createState() => _UserAccessPageState();
}

class _UserAccessPageState extends State<UserAccessPage> {
  final DatabaseReference _cameraAccessRef =
      FirebaseDatabase.instance.ref().child('camera_access');
  final DatabaseReference _usersRef =
      FirebaseDatabase.instance.ref().child('users');
  List<Map<String, dynamic>> _userAccessList = [];

  @override
  void initState() {
    super.initState();
    _fetchUserAccessData();
  }

  Future<void> _fetchUserAccessData() async {
    final snapshot = await _cameraAccessRef
        .orderByChild('camera_id')
        .equalTo(widget.cameraId)
        .once();

    if (snapshot.snapshot.value != null) {
      final accessData =
          (snapshot.snapshot.value as Map<dynamic, dynamic>).values.toList();
      final List<Map<String, dynamic>> tempUserAccessList = [];

      for (var access in accessData) {
        final userId = access['user_id'];
        if (userId == widget.currentUserId || access['is_invitation_accepted'] == false) {
          continue;
        }
        final userSnapshot = await _usersRef.child(userId).once();
        if (userSnapshot.snapshot.value != null) {
          final userData = userSnapshot.snapshot.value as Map<dynamic, dynamic>;
          tempUserAccessList.add({
            'name': "${userData['firstName']} ${userData['lastName']}",
            'email': userData['email'],
            'access': access,
          });
        }
      }

      setState(() {
        _userAccessList = tempUserAccessList;
      });
    }
  }

  void _removeUserAccess(String cameraId, String userId) {
    final id = '${cameraId}_$userId';
    _cameraAccessRef.child(id).remove().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User removed successfully')),
      );
      _fetchUserAccessData();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove user: $error')),
      );
    });
  }

  void _updateUserAccess(
      String cameraId, String userId, String field, bool value) {
    final id = '${cameraId}_$userId';
    _cameraAccessRef.child(id).update({field: value}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access updated successfully')),
      );
      _fetchUserAccessData();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update access: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'ReSecure',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: _userAccessList.length,
        itemBuilder: (context, index) {
          final user = _userAccessList[index];
          final access = user['access'];
          return Card(
            color: const Color(0xFFD9D9D9),
            margin: const EdgeInsets.all(8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: const BorderSide(color: Colors.black, width: 1.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.55,
                    child: Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name: ${user['name']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Email: ${user['email']}',
                            style: const TextStyle(fontSize: 9),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeUserAccess(
                                widget.cameraId, access['user_id']),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage Access:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(),
                            1: FixedColumnWidth(10),
                          },
                          children: [
                            TableRow(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(0, 13, 0, 0),
                                  child: Text(
                                    'View Live',
                                    style: TextStyle(fontSize: 10),
                                    textAlign: TextAlign.justify,
                                  ),
                                ),
                                Transform.scale(
                                  scale:
                                      0.6, // Adjust the scale value as needed
                                  child: Switch(
                                    value: access['view_live'],
                                    onChanged: (value) => _updateUserAccess(
                                      widget.cameraId,
                                      access['user_id'],
                                      'view_live',
                                      value,
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    activeColor: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            TableRow(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(0, 13, 0, 0),
                                  child: Text(
                                    'Camera Settings',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.6,
                                  child: Switch(
                                    value: access['camera_settings'],
                                    onChanged: (value) => _updateUserAccess(
                                      widget.cameraId,
                                      access['user_id'],
                                      'camera_settings',
                                      value,
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    activeColor: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            TableRow(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(0, 13, 0, 0),
                                  child: Text(
                                    'Recordings',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.6,
                                  child: Switch(
                                    value: access['view_recordings'],
                                    onChanged: (value) => _updateUserAccess(
                                      widget.cameraId,
                                      access['user_id'],
                                      'view_recordings',
                                      value,
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    activeColor: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddViewer(cameraId: widget.cameraId, ownerUserId: widget.ownerUserId),
            ),
          );
        },
        backgroundColor: const Color(0xFFD9D9D9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
        child: const Icon(
          Icons.person_add,
          color: Colors.black,
          size: 30,
        ),
      ),
    );
  }
}
