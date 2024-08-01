import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:resecure_user/view_live.dart';
import 'package:millicast_flutter_sdk/millicast_flutter_sdk.dart' as millicast;

class CameraViewPage extends StatefulWidget {
  final String cameraId;
  final String cameraUserId;

  const CameraViewPage({super.key, required this.cameraId, required this.cameraUserId});

  @override
  State<CameraViewPage> createState() => _CameraViewPageState();
}

class _CameraViewPageState extends State<CameraViewPage> {
  bool _isBackCamera = true;
  bool _isMotionDetectionOn = false;
  String? _deviceIdentifier;
  bool _isConnected = true;
  bool _isActive = true;
  bool _streamError = false;
  millicast.View? view;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  @override
  void initState() {
    initRenderers();
    super.initState();
    _loadCameraData();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _setUserConnectedStatus(false);
    super.dispose();
  }

  void initRenderers() async {
    await _localRenderer.initialize();
  }

  Future<void> _loadCameraData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cameraRef = FirebaseDatabase.instance
          .ref()
          .child('cameras')
          .child(widget.cameraUserId)
          .child(widget.cameraId);
      final cameraSnapshot = await cameraRef.once(DatabaseEventType.value);

      if (cameraSnapshot.snapshot.value != null) {
        final cameraData =
        cameraSnapshot.snapshot.value as Map<dynamic, dynamic>;

        _isMotionDetectionOn = cameraData['motion_detection'] ?? false;
        _isBackCamera = cameraData['back_camera'] ?? true;
        final bool isActive = cameraData['is_active'] ?? true;
        setState(() {
          _isConnected = isActive;
          _isActive = isActive;
        });
      }

      cameraRef.child('back_camera').onValue.listen((event) {
        if (event.snapshot.value as bool != _isBackCamera) {
          _toggleCamera();
        }
      });

      cameraRef.child('motion_detection').onValue.listen((event) {
        if (event.snapshot.value as bool != _isMotionDetectionOn) {
          setState(() {
            _isMotionDetectionOn = !_isMotionDetectionOn;
          });
          _toggleMotionDetection();
        }
      });
    }

    try {
      view = await viewConnect(_localRenderer, widget.cameraId);
    } catch (e) {
      setState(() {
        _streamError = true;
      });
    }

    setState(() {});
  }

  Future<void> _toggleMotionDetection() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cameraRef = FirebaseDatabase.instance
          .ref()
          .child('cameras')
          .child(widget.cameraUserId)
          .child(widget.cameraId);
      await cameraRef.update({
        'motion_detection': _isMotionDetectionOn,
      });
    }
  }

  Future<void> _toggleCamera() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _isBackCamera = !_isBackCamera;

      final cameraRef = FirebaseDatabase.instance
          .ref()
          .child('cameras')
          .child(widget.cameraUserId)
          .child(widget.cameraId);
      await cameraRef.update({
        'back_camera': _isBackCamera,
      });
      setState(() {});
    }
  }

  Future<void> _toggleCameraStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _deviceIdentifier != null) {
      final cameraRef = FirebaseDatabase.instance
          .ref()
          .child('cameras')
          .child(widget.cameraUserId)
          .child(widget.cameraId);

      final newStatus = !_isActive;
      await cameraRef.update({
        'is_active': newStatus,
      });

      setState(() {
        _isActive = newStatus;
        _isConnected = newStatus;
      });
    }
  }

  Future<void> _setUserConnectedStatus(bool status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cameraRef = FirebaseDatabase.instance
          .ref()
          .child('cameras')
          .child(widget.cameraUserId)
          .child(widget.cameraId);
      await cameraRef.update({"user_connected": status});
      view?.stop();
    }
  }

  Widget _buildCameraPreview() {
    if (_streamError) {
      return const Center(
        child: Text(
          'Camera is off',
          style: TextStyle(
            color: Colors.red,
            fontSize: 18,
          ),
        ),
      );
    }

    return RTCVideoView(
      _localRenderer,
      mirror: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _setUserConnectedStatus(false);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2C3E50),
          title: const Text(
            'ReSecure',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            children: [
              Row(
                children: [
                  Switch(
                    value: _isActive,
                    onChanged: (value) {
                      _toggleCameraStatus();
                    },
                  ),
                  Text(
                    _isActive ? 'On' : 'Off',
                    style: TextStyle(
                      color: _isActive ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 20.0,
                    height: 20.0,
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    _isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      color: _isConnected ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: _buildCameraPreview(),
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.switch_camera,
                          color: _isBackCamera ? Colors.green : Colors.red,
                          size: 25,
                        ),
                        onPressed: () {
                          setState(() {
                            _toggleCamera();
                          });
                        },
                      ),
                      Text(
                        'Switch Camera',
                        style: TextStyle(
                          color: _isBackCamera ? Colors.green : Colors.red,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.motion_photos_on,
                          color: _isMotionDetectionOn ? Colors.green : Colors.red,
                          size: 25,
                        ),
                        onPressed: () {
                          setState(() {
                            _isMotionDetectionOn = !_isMotionDetectionOn;
                            _toggleMotionDetection();
                          });
                        },
                      ),
                      Text(
                        'Motion Detection',
                        style: TextStyle(
                          color: _isMotionDetectionOn ? Colors.green : Colors.red,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
