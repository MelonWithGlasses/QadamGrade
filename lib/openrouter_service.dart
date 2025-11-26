import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenRouterService {
  static String get apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
  static const List<String> baseUrls = [
    'https://openrouter.ai/api/v1/chat/completions',
    'https://api.openrouter.ai/v1/chat/completions',
    'https://openrouter.ai/api/v1/chat/completions',
  ];
  static const Duration timeout = Duration(seconds: 45);

  Future<String> evaluateHomework({
    required dynamic taskInput, // String or List<String>
    required String taskType, // 'image' or 'text'
    required dynamic studentAnswerInput, // String or List<String>
    required String studentAnswerType, // 'image' or 'text'
  }) async {
    try {
      List<Map<String, dynamic>> content = [
        {
          'type': 'text',
          'text': 'Проанализируй домашнее задание. Сначала идет задание, затем ответ ученика.'
        }
      ];

      if (taskType == 'image') {
        List<String> images = (taskInput is List) ? List<String>.from(taskInput) : [taskInput as String];
        for (var imagePath in images) {
          final taskImageBase64 = await _imageToBase64(imagePath);
          content.add({
            'type': 'image_url',
            'image_url': {
              'url': 'data:image/jpeg;base64,$taskImageBase64'
            }
          });
        }
        content.add({
          'type': 'text',
          'text': '\n\nЗАДАНИЕ (изображения выше):'
        });
      } else {
        content.add({
          'type': 'text',
          'text': '\n\nЗАДАНИЕ:\n$taskInput'
        });
      }

      if (studentAnswerType == 'image') {
        List<String> images = (studentAnswerInput is List) ? List<String>.from(studentAnswerInput) : [studentAnswerInput as String];
        for (var imagePath in images) {
          final studentAnswerImageBase64 = await _imageToBase64(imagePath);
          content.add({
            'type': 'image_url',
            'image_url': {
              'url': 'data:image/jpeg;base64,$studentAnswerImageBase64'
            }
          });
        }
        content.add({
          'type': 'text',
          'text': '\n\nОТВЕТ УЧЕНИКА (изображения выше):'
        });
      } else {
        content.add({
          'type': 'text',
          'text': '\n\nОТВЕТ УЧЕНИКА:\n$studentAnswerInput'
        });
      }

      http.Response? response;
      String? lastError;
      
      for (int urlIndex = 0; urlIndex < baseUrls.length; urlIndex++) {
        for (int retry = 0; retry < 3; retry++) {
          try {
            // debugPrint('Trying URL: ${baseUrls[urlIndex]} (attempt ${retry + 1})');
            
            if (retry > 0) {
              await Future.delayed(Duration(seconds: retry * 2));
            }
            
            response = await http.post(
              Uri.parse(baseUrls[urlIndex]),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $apiKey',
                'User-Agent': 'QadamGrade/1.0',
                'Accept': 'application/json',
                'Connection': 'keep-alive',
              },
              body: jsonEncode({
                'model': 'google/gemma-3-27b-it:free',
                'messages': [
                  {
                    'role': 'system',
                    'content': 'Ты — высококвалифицированный школьный учитель в Казахстане. Твоя задача: проанализировать ЗАДАНИЕ и ОТВЕТ УЧЕНИКА. Поставь приблизительную оценку по 10-балльной шкале. Затем, используя Markdown, объясни, где ошибка и что ученик должен улучшить в своем ответе. Отвечай доброжелательно на русском языке.'
                  },
                  {
                    'role': 'user',
                    'content': content
                  }
                ],
              }),
            ).timeout(timeout);
            
            if (response.statusCode == 200) {
              // debugPrint('Success with URL: ${baseUrls[urlIndex]}');
              break;
            } else {
              lastError = 'HTTP ${response.statusCode}: ${response.body}';
            }
          } catch (e) {
            lastError = e.toString();
            // debugPrint('URL ${baseUrls[urlIndex]} attempt ${retry + 1} failed: $e');
          }
          
          if (response != null && response.statusCode == 200) {
            break;
          }
        }
        
        if (response != null && response.statusCode == 200) {
          break;
        }
      }
      
      if (response == null) {
        throw Exception('Не удалось подключиться к OpenRouter. Попробуйте:\n'
            '• Проверить интернет-соединение\n'
            '• Использовать VPN\n'
            '• Сменить DNS на 8.8.8.8 или 1.1.1.1\n'
            '• Последняя ошибка: $lastError');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // debugPrint('API Response: ${response.body}');
        
        if (data['choices'] != null && 
            data['choices'].isNotEmpty && 
            data['choices'][0]['message'] != null &&
            data['choices'][0]['message']['content'] != null) {
          return data['choices'][0]['message']['content'];
        } else if (data['content'] != null) {
          return data['content'];
        } else if (data['text'] != null) {
          return data['text'];
        } else {
          return 'Получен неожиданный формат ответа от сервера';
        }
      } else if (response.statusCode == 401) {
        throw Exception('Ошибка авторизации API. Проверьте ключ API.');
      } else if (response.statusCode == 429) {
        throw Exception('Слишком много запросов. Попробуйте снова через несколько минут.');
      } else if (response.statusCode >= 500) {
        throw Exception('Ошибка сервера OpenRouter. Попробуйте снова позже.');
      } else {
        throw Exception('API Error (${response.statusCode}): ${response.body}');
      }
    } on SocketException catch (e) {
      if (e.message.contains('No address associated with hostname') || 
          e.message.contains('Host not found') ||
          e.message.contains('nodename nor servname provided') ||
          e.message.contains('Failed host lookup')) {
        throw Exception('DNS ошибка: не удалось найти openrouter.ai\n\n'
            '⚡️ БЫСТРЫЕ РЕШЕНИЯ:\n'
            '1. 📱 Включите VPN (самый надежный способ)\n'
            '   • Рекомендуемые: TurboVPN, ProtonVPN, NordVPN\n'
            '\n'
            '2. 🌐 Смените DNS на телефоне/компьютере:\n'
            '   • Android: Настройки → Wi-Fi → [ваша сеть] → Дополнительно → DNS\n'
            '   • iOS: Настройки → Wi-Fi → [ваша сеть] → Настроить DNS → Вручную\n'
            '   • Введите: 8.8.8.8 (Google) или 1.1.1.1 (Cloudflare)\n'
            '\n'
            '3. 🔄 Перезагрузите интернет:\n'
            '   • Выключите/включите Wi-Fi\n'
            '   • Перезагрузите роутер\n'
            '   • Попробуйте мобильный интернет\n'
            '\n'
            '4. 💻 Если ничего не помогает:\n'
            '   • Проверьте блокировку доменов провайдером\n'
            '   • Попробуйте другую сеть');
      } else if (e.message.contains('Network is unreachable')) {
        throw Exception('Сеть недоступна. Проверьте подключение к интернету.');
      } else if (e.message.contains('Connection refused')) {
        throw Exception('Соединение отклонено. Сервер перегружен, попробуйте позже.');
      } else {
        throw Exception('Ошибка сети: ${e.message}');
      }
    } on HttpException catch (e) {
      throw Exception('HTTP ошибка: ${e.message}');
    } on FormatException {
      throw Exception('Ошибка обработки ответа сервера');
    } on TimeoutException {
      throw Exception('Сервер не отвечает. Попробуйте:\n'
          '• Включить VPN\n'
          '• Проверить скорость интернета\n'
          '• Попробовать позже');
    } catch (e) {
      throw Exception('Ошибка оценки: $e');
    }
  }

  Future<String> _imageToBase64(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Ошибка конвертации изображения в base64: $e');
    }
  }
}