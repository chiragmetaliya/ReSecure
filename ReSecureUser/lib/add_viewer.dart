import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AddViewer extends StatefulWidget {
  final String cameraId;
  final String ownerUserId;

  const AddViewer({super.key, required this.cameraId, required this.ownerUserId});

  @override
  State<AddViewer> createState() => _AddViewerState();
}

class _AddViewerState extends State<AddViewer> {
  final TextEditingController _emailController = TextEditingController();
  final DatabaseReference _cameraAccessRef =
  FirebaseDatabase.instance.ref().child('camera_access');
  final DatabaseReference _usersRef =
  FirebaseDatabase.instance.ref().child('users');

  bool _viewLive = false;
  bool _cameraSettings = false;
  bool _viewRecordings = false;

  Future<void> _sendInvitation() async {
    final email = _emailController.text.trim();
    final userSnapshot = await _usersRef.orderByChild('email').equalTo(email).once();

    if (userSnapshot.snapshot.value != null) {
      final userId = await (userSnapshot.snapshot.value as Map<dynamic, dynamic>).keys.first;

      final accessData = {
        'camera_id': widget.cameraId,
        'user_id': userId,
        'owner_user_id': widget.ownerUserId,
        'view_live': _viewLive,
        'camera_settings': _cameraSettings,
        'view_recordings': _viewRecordings,
        'is_invitation_accepted': false,
        'is_admin': false,
      };

      await _cameraAccessRef.child('${widget.cameraId}_$userId').set(accessData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation sent successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
    }
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Person',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Enter registered email address of user.'),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Email Address',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Set Access Of User',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('View Live'),
                Switch(
                  value: _viewLive,
                  onChanged: (value) {
                    setState(() {
                      _viewLive = value;
                    });
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Camera Settings'),
                Switch(
                  value: _cameraSettings,
                  onChanged: (value) {
                    setState(() {
                      _cameraSettings = value;
                    });
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recordings'),
                Switch(
                  value: _viewRecordings,
                  onChanged: (value) {
                    setState(() {
                      _viewRecordings = value;
                    });
                  },
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendInvitation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                child: const Text(
                  'Send Invitation',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
