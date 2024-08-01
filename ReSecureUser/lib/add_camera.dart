import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class AddCameraPage extends StatefulWidget {
  const AddCameraPage({super.key});

  @override
  State<AddCameraPage> createState() => _AddCameraPageState();
}

class _AddCameraPageState extends State<AddCameraPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _camerasRef =
      FirebaseDatabase.instance.ref().child('camera_codes');
  final DatabaseReference _cameraAccessRef =
      FirebaseDatabase.instance.ref().child('camera_access');
  final DatabaseReference _cameraDetailsRef =
      FirebaseDatabase.instance.ref().child('cameras');
  final TextEditingController _codeController = TextEditingController();
  String? _cameraCode;
  String? _cameraName;
  bool? _isActive;
  String userId = ""; // Retrieve this based on your app's logic
  String cameraId = ""; // Retrieve this based on your app's logic
  String ownerUserID = "";
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setUserId();
  }

  Future<void> _setUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
    }
  }

  void _checkCameraCode(String code) async {
    final user = _auth.currentUser;
    if (user != null) {
      final cameraSnapshot = await _camerasRef.orderByChild(code).once();

      if (cameraSnapshot.snapshot.key != null) {
        final cameras = cameraSnapshot.snapshot.value as Map<dynamic, dynamic>;
        String fetchedCameraId;
        String fetchedUserId;
        Map<dynamic, dynamic> fetchedCamera;

        if (cameras[code] != null) {
          fetchedCameraId = cameras[code]["camera_id"];
          fetchedUserId = cameras[code]["user_id"];

          final cameraDetailsSanpshot = await _cameraDetailsRef
              .child(fetchedUserId)
              .child(fetchedCameraId)
              .once();
          fetchedCamera =
              cameraDetailsSanpshot.snapshot.value as Map<dynamic, dynamic>;

          setState(() {
            _cameraCode = code;
            _cameraName = fetchedCamera['name'];
            _isActive = fetchedCamera['is_active'];
            cameraId = fetchedCameraId;
            ownerUserID = fetchedUserId;
          });
        } else {
          setState(() {
            _errorMessage = "Invalid Code";
          });
        }
      }
    }
  }

  void _scanQRCode() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    controller.scannedDataStream.listen((scanData) {
      final scannedCode = scanData.code;
      if (scannedCode != null) {
        _checkCameraCode(scannedCode);
        controller.dispose();
        Navigator.pop(context);
      }
    });
  }

  void _addCamera() async {
    final user = _auth.currentUser;
    if (user != null && _cameraCode != null) {
      final cameraAccessId = '${cameraId}_$userId';
      final cameraAccessSnapshot =
          await _cameraAccessRef.child(cameraAccessId).once();

      if (!cameraAccessSnapshot.snapshot.exists) {
        await _cameraAccessRef.child(cameraAccessId).set({
          'camera_id': cameraId,
          'user_id': userId,
          'owner_user_id': ownerUserID,
          'is_admin': true,
          'view_live': true,
          'view_recordings': true,
          'camera_settings': true,
          'is_invitation_accepted': true,
        });
      } else {
        await _cameraAccessRef.child(cameraAccessId).update({
          'is_admin': false,
          'view_live': true,
          'view_recordings': true,
          'camera_settings': true,
          'is_invitation_accepted': true,
        });
      }

      print('Dbg Camera Added');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Camera'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  'Add New Camera',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Enter Code from ReSecure Camera app',
                  style: TextStyle(fontSize: 16),
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
                          _cameraCode != null && _cameraCode!.length > index
                              ? _cameraCode![index]
                              : '',
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
              const SizedBox(
                height: 10,
              ),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'Enter 6 digit code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onChanged: (code) {
                  if (code.length == 6) {
                    _checkCameraCode(code);
                  }
                },
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'or',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, size: 40),
                  onPressed: _scanQRCode,
                ),
              ),
              const SizedBox(height: 20),
              if (_cameraName != null && _isActive != null) ...[
                Text(
                  'Camera Name: $_cameraName',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  'Status: ${_isActive! ? "Active" : "Inactive"}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addCamera,
                  child: const Text('Add Camera'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
