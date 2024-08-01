import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:intl/intl.dart';
import 'package:millicast_flutter_sdk/millicast_flutter_sdk.dart';
import 'package:image/image.dart' as img;
// import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:resecure_camera/publisher.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final TextEditingController _cameraNameController = TextEditingController();
  bool _isBackCamera = true;
  bool _isMotionDetectionOn = false;
  String? _deviceIdentifier;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isConnected = true;
  StreamSubscription<DatabaseEvent>? _userConnectedSubscription;
  bool isJoined = false;
  Publish? publish;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  // Motion detection variables
  bool _isProcessing = false;
  bool _motionDetected = false;
  img.Image? _backgroundImage;
  int minSizeThreshold = 10000; // Adjust the threshold for your use case
  bool _startDetection = false;
  // final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  bool _recording = false;
  bool _firstMotion = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getDeviceIdentifier();
  }

  @override
  void dispose() {
    _cameraNameController.dispose();
    _cameraController?.dispose();
    _userConnectedSubscription?.cancel();
    _localRenderer.dispose();
    publish?.stop();
    super.dispose();
  }

  void initRenderers() async {
    await _localRenderer.initialize();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _setCameraController(
        _isBackCamera ? CameraLensDirection.back : CameraLensDirection.front);
  }

  Future<void> _setCameraController(CameraLensDirection direction) async {
    final selectedCamera =
        _cameras?.firstWhere((camera) => camera.lensDirection == direction);
    if (selectedCamera != null) {
      _cameraController =
          CameraController(selectedCamera, ResolutionPreset.high);
    }
    await _cameraController?.initialize();
    setState(() {});
    await _startDetectingMotion();
  }

  Future<void> _startDetectingMotion() async {
    print("Dbg motion detection: $_isMotionDetectionOn");
    if (_isMotionDetectionOn) {
      // Start detecting motion after given seconds
      Future.delayed(const Duration(seconds: 10), () {
        setState(() {
          _startDetection = true;
        });
      });
      try {
        _cameraController?.startImageStream((image) {
          if (_startDetection && !_isProcessing) {
            _processImageForMotionDetection(image);
          }
        });
        setState(() {});
      } catch (e) {
        print('Error initializing camera: $e');
      }
    } else {
      if (_cameraController!.value.isStreamingImages) {
        _cameraController?.stopImageStream();
        // _startDetection = false;
        _isProcessing = false;
      }
    }
  }

  Future<void> _loadCameraData(String deviceIdentifier) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cameraRef = FirebaseDatabase.instance
          .ref()
          .child('cameras')
          .child(user.uid)
          .child(deviceIdentifier);
      final cameraSnapshot = await cameraRef.once();

      if (cameraSnapshot.snapshot.value != null) {
        final cameraData =
            cameraSnapshot.snapshot.value as Map<dynamic, dynamic>;

        _cameraNameController.text = cameraData['name'] ?? '';
        _isMotionDetectionOn = cameraData['motion_detection'] ?? false;
        _isBackCamera = cameraData['back_camera'] ?? true;

        _setCameraController(_isBackCamera
            ? CameraLensDirection.back
            : CameraLensDirection.front);
        final bool isActive = cameraData['is_active'] ?? true;
        setState(() {
          _isConnected = isActive;
        });

        if (cameraData["user_connected"] == true) {
          _userConnected(true, cameraRef, cameraData);
        } else {
          _userConnectedSubscription =
              cameraRef.child('user_connected').onValue.listen((event) {
            final isUserConnected = event.snapshot.value as bool?;
            if (isUserConnected != null) {
              _userConnected(isUserConnected, cameraRef, cameraData);
            }
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
      } else {
        _registerCamera(deviceIdentifier);
      }
    }
  }

  void _userConnected(bool isUserConnected, cameraRef, cameraData) async {
    if (isUserConnected == true) {
      isJoined = true;
      _cameraController?.dispose();
      initRenderers();
      publish = await publishConnect(
          _localRenderer, _deviceIdentifier.toString(), _isBackCamera);
      print("Dbg Here");
      setState(() {});
    } else {
      isJoined = false;
      publish?.stop();
      publish = null;
      _initializeCamera();
      print("User not connected");
      setState(() {});
    }
  }

  Future<void> _updateCameraName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cameraRef = FirebaseDatabase.instance
          .ref()
          .child('cameras')
          .child(user.uid)
          .child(_deviceIdentifier!);
      await cameraRef.update({
        'name': _cameraNameController.text,
      });
    }
  }

  Future<void> _toggleMotionDetection() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cameraRef = FirebaseDatabase.instance
          .ref()
          .child('cameras')
          .child(user.uid)
          .child(_deviceIdentifier!);
      await cameraRef.update({
        'motion_detection': _isMotionDetectionOn,
      });
    }
  }

  Future<void> _toggleCamera() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _isBackCamera = !_isBackCamera;
      if (!isJoined) {
        _setCameraController(_isBackCamera
            ? CameraLensDirection.back
            : CameraLensDirection.front);
      } else {
        publish?.stop();
        publish = null;
        publish = await publishConnect(
            _localRenderer, _deviceIdentifier.toString(), _isBackCamera);
        print("Dbg Here2");
        setState(() {});
      }

      final cameraRef = FirebaseDatabase.instance
          .ref()
          .child('cameras')
          .child(user.uid)
          .child(_deviceIdentifier!);
      await cameraRef.update({
        'back_camera': _isBackCamera,
      });
    }
  }

  Future<void> _getDeviceIdentifier() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      _deviceIdentifier = androidInfo.androidId;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      _deviceIdentifier = iosInfo.identifierForVendor;
    }

    if (_deviceIdentifier != null) {
      _loadCameraData(_deviceIdentifier!);
    }
  }

  Future<void> _registerCamera(String deviceIdentifier) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cameraRef = FirebaseDatabase.instance
          .ref()
          .child('cameras')
          .child(user.uid)
          .child(deviceIdentifier);

      await cameraRef.set({
        'name': 'Camera ${Random().nextInt(1000)}',
        'motion_detection': false,
        'back_camera': true,
        'is_active': true,
        'device_identifier': deviceIdentifier,
        'user_connected': false,
      });

      _loadCameraData(deviceIdentifier);
    }
  }

  Widget _buildCameraPreview() {
    print("initialized: ${_cameraController!.value.isInitialized}");
    if (isJoined == false) {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      } else {
        return AspectRatio(
          aspectRatio: _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        );
      }
    } else {
      return RTCVideoView(
        _localRenderer,
        mirror: false,
      );
    }
  }

  void _processImageForMotionDetection(CameraImage image) async {
    print("Dbg here1");
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    img.Image? currentImage = _convertYUV420ToImage(image);

    if (currentImage != null) {
      bool motionDetected = _detectMotion(currentImage);
      // print("Dbg motionDetected: $motionDetected, _motionDetected: $_motionDetected");
      if (motionDetected && !_motionDetected) {
        if (_firstMotion != true) {
          setState(() {
            _motionDetected = true;
          });
          print("Dbg Motion detected");
          _startRecording();
        } else {
          _firstMotion = false;
        }
      } else if (!motionDetected && _motionDetected) {
        setState(() {
          _motionDetected = false;
        });
      }
    }

    setState(() {
      _isProcessing = false;
    });
  }

  img.Image? _convertYUV420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;
    final Uint8List yBuffer = image.planes[0].bytes;
    final Uint8List uBuffer = image.planes[1].bytes;
    final Uint8List vBuffer = image.planes[2].bytes;

    img.Image imgBuffer = img.Image(width, height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int yValue = yBuffer[y * width + x];
        final int uValue = uBuffer[uvIndex];
        final int vValue = vBuffer[uvIndex];
        imgBuffer.setPixel(
            x,
            y,
            img.getColor(
              yValue,
              uValue,
              vValue,
            ));
      }
    }

    return imgBuffer;
  }

  bool _detectMotion(img.Image currentImage) {
    if (_backgroundImage == null) {
      _backgroundImage = currentImage;
      return false;
    }

    int motionPixels = 0;
    for (int y = 0; y < currentImage.height; y++) {
      for (int x = 0; x < currentImage.width; x++) {
        int currentPixel = currentImage.getPixel(x, y);
        int backgroundPixel = _backgroundImage!.getPixel(x, y);
        if (_colorDifference(currentPixel, backgroundPixel) > 50) {
          motionPixels++;
        }
      }
    }

    bool motionDetected = motionPixels > minSizeThreshold;

    if (motionDetected) {
      _backgroundImage = currentImage;
    }

    return motionDetected;
  }

  int _colorDifference(int color1, int color2) {
    int r1 = img.getRed(color1);
    int g1 = img.getGreen(color1);
    int b1 = img.getBlue(color1);
    int r2 = img.getRed(color2);
    int g2 = img.getGreen(color2);
    int b2 = img.getBlue(color2);

    return ((r1 - r2).abs() + (g1 - g2).abs() + (b1 - b2).abs()) ~/ 3;
  }

  void _changeMotionDetected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Motion Detected'),
        content: const Text('Motion has been detected!'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    if (!_recording) {
      // String outputPath = 'motion_detected.mp4';
      if (!_cameraController!.value.isRecordingVideo) {
        await _cameraController?.stopImageStream();
        await _cameraController?.prepareForVideoRecording();
        await _cameraController?.startVideoRecording();
        print("Dbg recoding: ${_cameraController!.value.isRecordingVideo}");
        setState(() {
          _recording = true;
        });
      }
      Future.delayed(const Duration(seconds: 21), () async {
        if (_cameraController!.value.isRecordingVideo) {
          final file = await _cameraController?.stopVideoRecording();
          String? filePath = file?.path;
          print("Dbg file path: $filePath");

          if (filePath != null) {
            await _uploadVideoToFirebase(filePath);
          }

          setState(() {
            _motionDetected = false;
            _recording = false;
            _firstMotion = true;
          });
          await _startDetectingMotion();
        }
      });
    }
  }

  Future<void> _uploadVideoToFirebase(String filePath) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final file = File(filePath);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('${DateTime.now().toString()}.mp4');
        final uploadTask = storageRef.putFile(file);

        final taskSnapshot = await uploadTask.whenComplete(() => {});
        final downloadUrl = await taskSnapshot.ref.getDownloadURL();
        print("Dbg downloadUrl: $downloadUrl");

        await _saveVideoDetailsToDatabase(downloadUrl);
      } catch (e) {
        print('Dbg Error uploading video: $e');
      }
    }
  }

  Future<void> _saveVideoDetailsToDatabase(String downloadUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final databaseRef =
          FirebaseDatabase.instance.ref().child('recordings').push();
      final cameraId = _deviceIdentifier;
      final currentTime = DateTime.now();
      final dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(currentTime);
      final day = DateFormat('EEEE').format(currentTime);

      await databaseRef.set({
        'camera_id': cameraId,
        'storage_path': downloadUrl,
        'datetime': dateTime,
        'day': day,
      });

      print("Dbg video details saved to database");
    }
  }

  // Future<void> _stopRecording() async {
  //   if (_recording && _cameraController!.value.isRecordingVideo) {
  //     final file = await _cameraController?.stopVideoRecording();
  //     String? filePath = file?.path;
  //     print("Dbg file path: $filePath");

  //     setState(() {
  //       _recording = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cameraNameController,
                    decoration: InputDecoration(
                      hintText: "Camera Name",
                      filled: true,
                      fillColor: const Color(0xFFD9D9D9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 8.0,
                      ),
                    ),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _updateCameraName,
                ),
                const SizedBox(width: 15.0),
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
                          _startDetectingMotion();
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
    );
  }
}
