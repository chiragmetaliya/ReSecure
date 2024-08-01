import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:resecure_user/firebase_data_service.dart';
import 'package:resecure_user/recording.dart';

class RecordingsPage extends StatefulWidget {
  final String cameraId;

  const RecordingsPage({super.key, required this.cameraId});

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  DateTimeRange? _selectedDateRange;
  List<Recording> _recordings = [];
  FirebaseDataService firebaseDataService = FirebaseDataService();

  @override
  void initState() {
    super.initState();
    _fetchRecordings();
  }

  Future<void> _fetchRecordings() async {
    DateTime startDate = _selectedDateRange?.start ?? DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = _selectedDateRange?.end ?? DateTime.now();
    List<Recording> recordings = await firebaseDataService.fetchRecordings(widget.cameraId, startDate, endDate);
    setState(() {
      _recordings = recordings;
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedDateRange = null;
      _fetchRecordings();
    });
  }

  Future<void> _selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
        _fetchRecordings();
      });
    }
  }

  Future<void> _downloadVideo(String storagePath, String datetime) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      final url = ref.fullPath;
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/$datetime.mp4';
      await Dio().download(url, path);
      await GallerySaver.saveVideo(path, toDcim: true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloaded to Gallery')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download video: $e')));
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _selectDateRange,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, color: Colors.black),
                    SizedBox(width: 10),
                    Text(
                      'Date Range',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _fetchRecordings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Filter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _resetFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _recordings.length,
              itemBuilder: (context, index) {
                final recording = _recordings[index];
                return ListTile(
                  title: Text(DateFormat('yyyy-MM-dd HH:mm').format(recording.datetime)),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadVideo(recording.storagePath, recording.datetime.toString()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
