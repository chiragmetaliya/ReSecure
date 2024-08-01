import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';

import 'package:resecure_camera/firebase_data_service.dart';

class AddViewer extends StatefulWidget {
  const AddViewer({super.key});

  @override
  State<AddViewer> createState() => _AddViewerState();
}

class _AddViewerState extends State<AddViewer> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  String _cameraCode = "";
  String userId = ""; // Retrieve this based on your app's logic
  String cameraId = ""; // Retrieve this based on your app's logic

  @override
  void initState() {
    super.initState();
    _setCameraId().then((_) => _generateAndSetCode());
  }

  Future<void> _setCameraId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
    }
    cameraId = await FirebaseDataService().getDeviceIdentifier();
  }

  Future<void> _generateAndSetCode() async {
    String newCode;
    bool codeExists;

    do {
      newCode = _generateRandomCode();
      codeExists = await _checkCodeExists(newCode);
    } while (codeExists);

    setState(() {
      _cameraCode = newCode;
    });

    DatabaseReference codesDataReference = _database.ref('camera_codes');

    codesDataReference.once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        Map<dynamic, dynamic> cameraCodes =
            snapshot.value as Map<dynamic, dynamic>;

        cameraCodes.forEach((key, value) {
          if (value['user_id'] == userId && value['camera_id'] == cameraId) {
            _database
                .ref('camera_codes/$_cameraCode')
                .set({"user_id": userId, "camera_id": cameraId});
            _database.ref('camera_codes').child(key).remove();
            return;
          }
        });
      }

      print('Dbg No data available.');
      _database
          .ref('camera_codes/$_cameraCode')
          .set({"user_id": userId, "camera_id": cameraId});
    }).catchError((error) {
      print('Failed to retrieve data: $error');
    });
  }

  String _generateRandomCode() {
    final Random random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<bool> _checkCodeExists(String code) async {
    final cameraCodeSnapshot =
        await _database.ref('camera_codes').child(code).once();
    print("Dbg cameracodesnapshot: ${cameraCodeSnapshot.snapshot.value}");
    if (cameraCodeSnapshot.snapshot.value != null) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text('ReSecure Camera',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'CONNECT USER',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Enter this code in ReSecure',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2.0),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Center(
                      child: Text(
                        _cameraCode.isNotEmpty ? _cameraCode[index] : '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'or',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: QrImageView(
                data: _cameraCode,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Scan this QR code in ReSecure',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
