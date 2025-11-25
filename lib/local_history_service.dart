import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

part 'local_history_service.g.dart';

@HiveType(typeId: 0)
class EvaluationResult extends HiveObject {
  @HiveField(0)
  final String taskText;
  
  @HiveField(1)
  final String studentAnswerText;
  
  @HiveField(2)
  final String evaluationResult;
  
  @HiveField(3)
  final DateTime timestamp;

  EvaluationResult({
    required this.taskText,
    required this.studentAnswerText,
    required this.evaluationResult,
    required this.timestamp,
  });
}

class LocalHistoryService {
  static const String _boxName = 'evaluation_history';
  late Box<EvaluationResult> _historyBox;

  Future<void> initHive() async {
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);
      
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(EvaluationResultAdapter());
      }
      
      _historyBox = await Hive.openBox<EvaluationResult>(_boxName);
    } catch (e) {
      throw Exception('Ошибка инициализации Hive: $e');
    }
  }

  Future<void> saveResult({
    required String taskText,
    required String studentAnswerText,
    required String evaluationResult,
  }) async {
    try {
      final result = EvaluationResult(
        taskText: taskText,
        studentAnswerText: studentAnswerText,
        evaluationResult: evaluationResult,
        timestamp: DateTime.now(),
      );
      
      await _historyBox.add(result);
    } catch (e) {
      throw Exception('Ошибка сохранения результата: $e');
    }
  }

  List<EvaluationResult> getHistory() {
    try {
      return _historyBox.values.toList();
    } catch (e) {
      throw Exception('Ошибка загрузки истории: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      await _historyBox.clear();
    } catch (e) {
      throw Exception('Ошибка очистки истории: $e');
    }
  }
}