// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mesh_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeshMessageAdapter extends TypeAdapter<MeshMessage> {
  @override
  final int typeId = 0;

  @override
  MeshMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeshMessage(
      id: fields[0] as String,
      senderId: fields[1] as String,
      receiverId: fields[2] as String,
      payload: fields[3] as String,
      timestamp: fields[4] as DateTime,
      type: fields[5] as String,
      deliveryStatus: fields[6] as String,
      hopCount: fields[7] as int,
      pathTrace: (fields[8] as List).cast<String>(),
      isEncrypted: fields[9] as bool,
      senderName: fields[10] as String,
      ackRequired: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MeshMessage obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.senderId)
      ..writeByte(2)
      ..write(obj.receiverId)
      ..writeByte(3)
      ..write(obj.payload)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.deliveryStatus)
      ..writeByte(7)
      ..write(obj.hopCount)
      ..writeByte(8)
      ..write(obj.pathTrace)
      ..writeByte(9)
      ..write(obj.isEncrypted)
      ..writeByte(10)
      ..write(obj.senderName)
      ..writeByte(11)
      ..write(obj.ackRequired);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeshMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
