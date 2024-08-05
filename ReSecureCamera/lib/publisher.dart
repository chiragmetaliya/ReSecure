import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:millicast_flutter_sdk/millicast_flutter_sdk.dart';

Future publishConnect(RTCVideoRenderer localRenderer, String streamName,
    bool isBackCamera) async {
  // Setting subscriber options
  DirectorPublisherOptions directorPublisherOptions = DirectorPublisherOptions(
      token: 'YOUR TOKEN HERE',
      streamName: streamName);

  /// Define callback for generate new token
  tokenGenerator() => Director.getPublisher(directorPublisherOptions);
  print("Dbg stream name: $streamName");

  /// Create a new instance
  Publish publish =
      Publish(streamName: streamName, tokenGenerator: tokenGenerator);

  final Map<String, dynamic> constraints = <String, dynamic>{
    'audio': false,
    'video': {
      'facingMode': isBackCamera ? 'environment' : 'user', // Or 'environment'
    },
  };

  MediaStream stream = await navigator.mediaDevices.getUserMedia(constraints);
  localRenderer.srcObject = stream;

  //Publishing Options
  Map<String, dynamic> broadcastOptions = {'mediaStream': stream};
  //Some Android devices do not support h264 codec for publishing
  if (Platform.isAndroid) {
    broadcastOptions['codec'] = 'vp8';
  }

  /// Start connection to publisher
  try {
    await publish.connect(options: broadcastOptions);
    return publish;
  } catch (e) {
    throw Exception(e);
  }
}
