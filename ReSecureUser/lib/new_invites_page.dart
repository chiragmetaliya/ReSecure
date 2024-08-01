import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class NewInvitesPage extends StatefulWidget {
  final String userId;

  const NewInvitesPage({super.key, required this.userId});

  @override
  State<NewInvitesPage> createState() => _NewInvitesPageState();
}

class _NewInvitesPageState extends State<NewInvitesPage> {
  final DatabaseReference _cameraAccessRef = FirebaseDatabase.instance.ref().child('camera_access');
  final DatabaseReference _camerasRef = FirebaseDatabase.instance.ref().child('cameras');
  List<Map<dynamic, dynamic>> _invites = [];

  @override
  void initState() {
    super.initState();
    _fetchInvites();
  }

  Future<void> _fetchInvites() async {
    final cameraAccessSnapshot = await _cameraAccessRef
        .orderByChild('user_id')
        .equalTo(widget.userId)
        .once();

    if (cameraAccessSnapshot.snapshot.value != null) {
      final invitesData = cameraAccessSnapshot.snapshot.value as Map<dynamic, dynamic>;
      final List<Map<dynamic, dynamic>> invites = [];

      for (var invite in invitesData.values) {
        if (invite['is_invitation_accepted'] == false) {
          final cameraId = invite['camera_id'];
          final cameraSnapshot = await _camerasRef
              .child(invite["owner_user_id"])
              .child(cameraId)
              .once();

          if (cameraSnapshot.snapshot.value != null) {
            final camera = cameraSnapshot.snapshot.value as Map<dynamic, dynamic>;
            invites.add({
              'camera_id': cameraId,
              'camera_name': camera['name'],
              'is_admin': invite['is_admin'],
              'view_live': invite['view_live'],
              'camera_settings': invite['camera_settings'],
              'view_recordings': invite['view_recordings'],
            });
          }
        }
      }

      setState(() {
        _invites = invites;
      });
    }
  }

  Future<void> _acceptInvite(String cameraId) async {
    final inviteRef = _cameraAccessRef.child("${cameraId}_${widget.userId}");
    try {
      await inviteRef.update({'is_invitation_accepted': true});
      setState(() {
        _invites.removeWhere((invite) => invite['camera_id'] == cameraId);
      });
    } catch (e) {
      print('Error accepting invite: $e');
    }
  }

  Future<void> _rejectInvite(String cameraId) async {
    final inviteRef = _cameraAccessRef.child("${cameraId}_${widget.userId}");
    try {
      await inviteRef.remove();
      setState(() {
        _invites.removeWhere((invite) => invite['camera_id'] == cameraId);
      });
    } catch (e) {
      print('Error rejecting invite: $e');
    }
  }

  String _buildPermissionsText(Map<dynamic, dynamic> invite) {
    List<String> permissions = [];

    if (invite['is_admin'] == true) {
      permissions.add('Admin');
    } else {
      if (invite['view_live'] == true) {
        permissions.add('View Live');
      }
      if (invite['camera_settings'] == true) {
        permissions.add('Camera Settings');
      }
      if (invite['view_recordings'] == true) {
        permissions.add('View Recordings');
      }
    }

    return permissions.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'New Invites',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView.builder(
          itemCount: _invites.length,
          itemBuilder: (context, index) {
            final invite = _invites[index];
            final cameraName = invite['camera_name'] as String;
            final permissions = _buildPermissionsText(invite);

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
                    Text(
                      'Camera Name: $cameraName',
                      style: const TextStyle(fontSize: 14.0),
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      'Access: $permissions',
                      style: const TextStyle(fontSize: 12.0),
                    ),
                    const SizedBox(height: 10.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _acceptInvite(invite['camera_id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          child: const Text('Accept'),
                        ),
                        ElevatedButton(
                          onPressed: () => _rejectInvite(invite['camera_id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          child: const Text('Reject'),
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
    );
  }
}
