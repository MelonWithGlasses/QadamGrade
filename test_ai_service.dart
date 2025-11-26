// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Тестирование AI-сервиса QadamGrade...\n');
  
  String apiKey = '';
  
  // Load .env file manually
  try {
    final envFile = File('.env');
    if (await envFile.exists()) {
      final lines = await envFile.readAsLines();
      for (var line in lines) {
        if (line.trim().startsWith('OPENROUTER_API_KEY=')) {
          apiKey = line.split('=')[1].trim();
          print('✅ Found API key in .env');
          break;
        }
      }
    } else {
      print('❌ .env file not found');
    }
  } catch (e) {
    print('❌ Error reading .env file: $e');
  }

  if (apiKey.isEmpty) {
    print('❌ API Key not found in .env!');
    // Fallback for testing if .env fails (optional, but requested to use .env)
    return;
  }

  const baseUrls = [
    'https://openrouter.ai/api/v1/chat/completions',
    'https://api.openrouter.ai/v1/chat/completions',
  ];

  // Тестовые данные
  const testTask = "Реши уравнение: 2x + 5 = 15";
  const testAnswer = "2x + 5 = 15\n2x = 15 - 5\n2x = 10\nx = 5";

  print('📝 Задание: $testTask');
  print('📝 Ответ ученика: $testAnswer\n');

  List<Map<String, dynamic>> content = [
    {
      'type': 'text',
      'text': 'Проанализируй домашнее задание. Сначала идет задание, затем ответ ученика.'
    },
    {
      'type': 'text',
      'text': '\n\nЗАДАНИЕ:\n$testTask'
    },
    {
      'type': 'text',
      'text': '\n\nОТВЕТ УЧЕНИКА:\n$testAnswer'
    }
  ];

  bool success = false;
  String? lastError;

  for (int urlIndex = 0; urlIndex < baseUrls.length; urlIndex++) {
    for (int retry = 0; retry < 3; retry++) {
      try {
        print('🔄 Попытка ${retry + 1}: ${baseUrls[urlIndex]}');
        
        if (retry > 0) {
          print('⏳ Ожидание ${retry * 2} секунд...');
          await Future.delayed(Duration(seconds: retry * 2));
        }
        
        final response = await http.post(
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
        ).timeout(const Duration(seconds: 45));
        
        print('📊 Статус: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('✅ Успешный ответ!');
          
          if (data['choices'] != null && 
              data['choices'].isNotEmpty && 
              data['choices'][0]['message'] != null &&
              data['choices'][0]['message']['content'] != null) {
            
            final result = data['choices'][0]['message']['content'];
            print('\n🎯 Результат оценки:');
            print('=' * 50);
            print(result);
            print('=' * 50);
            success = true;
            break;
          }
        } else {
          lastError = 'HTTP ${response.statusCode}: ${response.body}';
          print('❌ Ошибка: $lastError');
        }
        
      } catch (e) {
        lastError = e.toString();
        print('❌ Исключение: $lastError');
        
        // If it's a DNS error, don't retry the same URL
        if (e.toString().contains('No address associated with hostname') ||
            e.toString().contains('Failed host lookup')) {
          print('🚫 DNS ошибка - переходим к следующему URL');
          break;
        }
      }
    }
    
    if (success) break;
  }

  if (!success) {
    print('\n❌ Все попытки неудачны!');
    print('Последняя ошибка: $lastError');
    print('\n💡 Рекомендации:');
    print('1. Включите VPN');
    print('2. Смените DNS на 8.8.8.8 или 1.1.1.1');
    print('3. Проверьте интернет-соединение');
  } else {
    print('\n🎉 AI-сервис работает корректно!');
  }
}