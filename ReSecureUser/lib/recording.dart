class Recording {
  final String id;
  final String cameraId;
  final DateTime datetime;
  final String day;
  final String storagePath;

  Recording({
    required this.id,
    required this.cameraId,
    required this.datetime,
    required this.day,
    required this.storagePath,
  });

  factory Recording.fromMap(Map<dynamic, dynamic> data) {
    return Recording(
      id: data['id'] ?? '',
      cameraId: data['camera_id'] ?? '',
      datetime: DateTime.tryParse(data['datetime']) ?? DateTime.now(),
      day: data['day'] ?? '',
      storagePath: data['storage_path'] ?? '',
    );
  }
}
