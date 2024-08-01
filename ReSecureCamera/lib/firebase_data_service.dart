import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:resecure_camera/recording.dart'; // Import your Recording model

class FirebaseDataService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<List<Recording>> fetchRecordings(
      String cameraId, DateTime startDate, DateTime endDate) async {
    final ref = _database
        .ref()
        .child('recordings')
        .orderByChild('camera_id')
        .equalTo(cameraId);
    final snapshot = await ref.get();
    List<Recording> recordings = [];
    for (var child in snapshot.children) {
      final data = child.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final recording = Recording.fromMap(data);
        if (recording.datetime.isAfter(startDate) &&
            recording.datetime.isBefore(endDate)) {
          recordings.add(recording);
        }
      }
    }
    return recordings;
  }

  Future<String> getDeviceIdentifier() async {
    String? deviceIdentifier;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceIdentifier = androidInfo.androidId;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceIdentifier = iosInfo.identifierForVendor;
    }
    return deviceIdentifier ?? '';
  }

  Future<List<Map<dynamic, dynamic>>> fetchCameraAccessByCameraId(
      String cameraId) async {
    final cameraAccessRef =
        FirebaseDatabase.instance.ref().child('camera_access');
    List<Map<String, dynamic>> cameraAccessList = [];

    try {
      // Check if camera_access table exists
      DatabaseEvent tableSnapshot = await cameraAccessRef.once();
      if (!tableSnapshot.snapshot.exists) {
        print('camera_access table does not exist. Creating table...');
        await cameraAccessRef.set({});
      }

      // Fetch all camera access entries
      DatabaseEvent snapshot = await cameraAccessRef.once();
      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic>? values =
            snapshot.snapshot.value as Map<dynamic, dynamic>?;
        if (values != null) {
          for (var entry in values.entries) {
            Map<dynamic, dynamic> accessData = entry.value;
            if (accessData['camera_id'] == cameraId) {
              // print("Dbg here");
              final userDetails = await fetchUserDetails(accessData['user_id']);
              cameraAccessList.add({
                'key': entry.key,
                ...accessData,
                ...userDetails,
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching camera access by camera ID: $e');
    }
    return cameraAccessList;
  }

  Future<Map<dynamic, dynamic>> fetchUserDetails(String userId) async {
    final userRef =
        FirebaseDatabase.instance.ref().child('users').child(userId);
    final snapshot = await userRef.once();
    final user = _auth.currentUser;

    if (snapshot.snapshot.value != null) {
      Map<dynamic, dynamic> userData =
          snapshot.snapshot.value as Map<dynamic, dynamic>;
      return {
        'name': '${userData['firstName']} ${userData['lastName']}',
        'email': userData['email'],
      };
    } else if (user != null && user.uid == userId) {
      return {
        'name': user.displayName ?? '',
        'email': user.email ?? '',
      };
    } else {
      return {
        'name': 'Unknown',
        'email': 'Unknown',
      };
    }
  }
}
