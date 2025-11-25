// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_history_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EvaluationResultAdapter extends TypeAdapter<EvaluationResult> {
  @override
  final int typeId = 0;

  @override
  EvaluationResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EvaluationResult(
      taskText: fields[0] as String,
      studentAnswerText: fields[1] as String,
      evaluationResult: fields[2] as String,
      timestamp: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, EvaluationResult obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.taskText)
      ..writeByte(1)
      ..write(obj.studentAnswerText)
      ..writeByte(2)
      ..write(obj.evaluationResult)
      ..writeByte(3)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
