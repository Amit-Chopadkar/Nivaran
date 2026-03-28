import 'package:hive/hive.dart';

part 'mesh_message.g.dart';

@HiveType(typeId: 0)
class MeshMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String senderId;

  @HiveField(2)
  final String receiverId;

  @HiveField(3)
  final String payload;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String type; // 'chat', 'call_offer', 'call_answer', 'ice_candidate'

  @HiveField(6)
  bool isDelivered;

  @HiveField(7)
  int hopCount;

  @HiveField(8)
  List<String> pathTrace;

  @HiveField(9)
  bool isEncrypted;

  MeshMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.payload,
    required this.timestamp,
    required this.type,
    this.isDelivered = false,
    this.hopCount = 0,
    this.pathTrace = const [],
    this.isEncrypted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'isDelivered': isDelivered,
      'hopCount': hopCount,
      'pathTrace': pathTrace,
      'isEncrypted': isEncrypted,
    };
  }

  factory MeshMessage.fromJson(Map<String, dynamic> json) {
    return MeshMessage(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      payload: json['payload'],
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'],
      isDelivered: json['isDelivered'] ?? false,
      hopCount: json['hopCount'] ?? 0,
      pathTrace: List<String>.from(json['pathTrace'] ?? []),
      isEncrypted: json['isEncrypted'] ?? false,
    );
  }
}
