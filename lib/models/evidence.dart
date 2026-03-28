import 'package:hive/hive.dart';

part 'evidence.g.dart';

@HiveType(typeId: 4)
class Evidence extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // 'Audio', 'Video', 'Photo'

  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String? duration; // For audio/video

  @HiveField(5)
  final bool isSOS; // Whether it was captured during SOS

  Evidence({
    required this.id,
    required this.type,
    required this.filePath,
    required this.timestamp,
    this.duration,
    this.isSOS = false,
  });
}
