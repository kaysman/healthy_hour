// GENERATED CODE - hand-written adapter (kept in sync with @HiveType fields).

part of 'session_model.dart';

class SessionModelAdapter extends TypeAdapter<SessionModel> {
  @override
  final int typeId = 1;

  @override
  SessionModel read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return SessionModel(
      id: fields[0] as String,
      kindIndex: fields[1] as int,
      startedAt: fields[2] as DateTime,
      endedAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SessionModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kindIndex)
      ..writeByte(2)
      ..write(obj.startedAt)
      ..writeByte(3)
      ..write(obj.endedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
