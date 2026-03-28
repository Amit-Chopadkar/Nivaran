// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evidence.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EvidenceAdapter extends TypeAdapter<Evidence> {
  @override
  final int typeId = 4;

  @override
  Evidence read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Evidence(
      id: fields[0] as String,
      type: fields[1] as String,
      filePath: fields[2] as String,
      timestamp: fields[3] as DateTime,
      duration: fields[4] as String?,
      isSOS: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Evidence obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.isSOS);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
