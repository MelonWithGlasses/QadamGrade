import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'image_scanner_service.dart';
import 'openrouter_service.dart';
import 'local_history_service.dart';
import 'image_editor_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// --- Custom Painters (Assets) ---

// 1. ИСПРАВЛЕННОЕ Солнце Казахстана
class KazakhSunPainter extends CustomPainter {
  final Color color;
  KazakhSunPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    
    // Уменьшаем радиус диска, чтобы лучи были длиннее
    final diskRadius = size.width * 0.22; 
    final rayLength = size.width * 0.22;
    final rayStart = diskRadius + (size.width * 0.02); // Отступ от диска

    // 1. Центральный диск
    canvas.drawCircle(center, diskRadius, paint);

    // 2. Лучи-зерна (32 шт)
    for (int i = 0; i < 32; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * (2 * math.pi / 32));
      
      final rayPath = Path();
      // Рисуем "зерно": начинается узким, расширяется, сужается к концу
      rayPath.moveTo(0, -rayStart); 
      // Левая дуга
      rayPath.quadraticBezierTo(
        -size.width * 0.03, -rayStart - (rayLength * 0.5), 
        0, -rayStart - rayLength
      );
      // Правая дуга (возврат)
      rayPath.quadraticBezierTo(
        size.width * 0.03, -rayStart - (rayLength * 0.5), 
        0, -rayStart
      );
      
      canvas.drawPath(rayPath, paint);
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(KazakhSunPainter oldDelegate) => oldDelegate.color != color;
}

// 2. Орнамент (Минималистичный)
class OrnamentPainter extends CustomPainter {
  final Color color;
  OrnamentPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2; // Тонкие линии для минимализма
      
    final path = Path();
    // Стилизованные рога
    path.moveTo(size.width * 0.2, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.2, size.width * 0.5, size.height * 0.2);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.2, size.width * 0.8, size.height * 0.6);
    
    // Внутренние завитки
    path.moveTo(size.width * 0.35, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.35, size.height * 0.4, size.width * 0.5, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.65, size.height * 0.4, size.width * 0.65, size.height * 0.6);

    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(OrnamentPainter oldDelegate) => oldDelegate.color != color;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  LocalHistoryService? localHistoryService;
  if (!kIsWeb) {
    localHistoryService = LocalHistoryService();
    await localHistoryService.initHive();
  }
  runApp(QadamGradeApp(localHistoryService: localHistoryService));
}

class QadamGradeApp extends StatelessWidget {
  final LocalHistoryService? localHistoryService;
  const QadamGradeApp({super.key, this.localHistoryService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QadamGrade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900 (Deep Dark)
        useMaterial3: true,
        // Шрифт Inter для чистого UI
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: HomeworkCheckerScreen(localHistoryService: localHistoryService),
    );
  }
}

class HomeworkCheckerScreen extends StatefulWidget {
  final LocalHistoryService? localHistoryService;
  const HomeworkCheckerScreen({super.key, this.localHistoryService});

  @override
  State<HomeworkCheckerScreen> createState() => _HomeworkCheckerScreenState();
}

class _HomeworkCheckerScreenState extends State<HomeworkCheckerScreen> with TickerProviderStateMixin {
  final ImageScannerService _imageScannerService = ImageScannerService();
  final OpenRouterService _openRouterService = OpenRouterService();
  
  List<String> _taskImages = [];
  List<String> _studentAnswerImages = [];
  String _taskText = '';
  String _studentAnswerText = '';
  String _evaluationResult = '';
  int _currentScore = 0;

  String _taskInputType = 'text';
  String _answerInputType = 'text';
  
  String _stage = 'idle'; // idle -> analyzing -> centering -> expanding/settling -> result
  
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  
  late AnimationController _vortexController;
  
  @override
  void initState() {
    super.initState();
    _vortexController = AnimationController(
      duration: const Duration(seconds: 8), // Очень медленное вращение для премиальности
      vsync: this,
    );
  }

  @override
  void dispose() {
    _vortexController.dispose();
    _taskController.dispose();
    _answerController.dispose();
    _imageScannerService.dispose();
    super.dispose();
  }

  // --- LOGIC ---

  Future<void> _handleAnalyze() async {
    bool hasTask = (_taskInputType == 'text' && _taskText.isNotEmpty) || (_taskInputType == 'photo' && _taskImages.isNotEmpty);
    bool hasAnswer = (_answerInputType == 'text' && _studentAnswerText.isNotEmpty) || (_answerInputType == 'photo' && _studentAnswerImages.isNotEmpty);
    
    if (!hasTask || !hasAnswer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _stage = 'analyzing';
      _evaluationResult = '';
    });
    _vortexController.repeat();

    try {
      String taskContent = _taskInputType == 'text' ? _taskText : _taskImages.first;
      String answerContent = _answerInputType == 'text' ? _studentAnswerText : _studentAnswerImages.first;

      final result = await _openRouterService.evaluateHomework(
        taskInput: taskContent,
        taskType: _taskInputType == 'text' ? 'text' : 'image',
        studentAnswerInput: answerContent,
        studentAnswerType: _answerInputType == 'text' ? 'text' : 'image',
      );

      int score = _extractScore(result);
      await Future.delayed(const Duration(seconds: 2)); // UX pause

      setState(() {
        _currentScore = score;
        _evaluationResult = result;
        _stage = 'centering';
      });

      await Future.delayed(const Duration(milliseconds: 800));
      
      setState(() {
        if (score == 10) {
          _stage = 'expanding';
        } else {
          _stage = 'settling';
        }
      });

      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _stage = 'result';
      });
      
      if (_stage == 'result') _vortexController.stop();

      if (widget.localHistoryService != null) {
        widget.localHistoryService!.saveResult(
          taskText: 'Задание',
          studentAnswerText: 'Ответ',
          evaluationResult: result,
        );
      }

    } catch (e) {
      setState(() => _stage = 'idle');
      _vortexController.stop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    }
  }

  int _extractScore(String text) {
    final regex = RegExp(r'(\d+)/10');
    final match = regex.firstMatch(text);
    if (match != null) return int.parse(match.group(1)!);
    if (text.toLowerCase().contains('отлично')) return 10;
    return 7;
  }

  void _reset() {
    setState(() {
      _stage = 'idle';
      _taskImages.clear();
      _studentAnswerImages.clear();
      _taskController.clear();
      _answerController.clear();
      _taskText = '';
      _studentAnswerText = '';
    });
    _vortexController.stop();
  }

  Future<void> _pickImage(bool isTask) async {
    try {
      final path = await _imageScannerService.scanImage();
      if (path.isEmpty) return;
      setState(() {
        if (isTask) _taskImages = [path];
        else _studentAnswerImages = [path];
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Matrix4 _getSunTransform() {
    final matrix = Matrix4.identity();
    switch (_stage) {
      case 'idle':
        matrix.scale(0.0);
        break;
      case 'analyzing':
        matrix.scale(1.0);
        matrix.translate(0.0, -80.0); // Орбита
        break;
      case 'centering':
        matrix.scale(0.8);
        matrix.translate(0.0, 0.0); // Центр
        break;
      case 'expanding':
        matrix.scale(30.0); // Взрыв
        break;
      case 'settling':
      case 'result':
        if (_currentScore == 10) {
           matrix.scale(30.0);
        } else {
           matrix.scale(0.6);
           matrix.translate(0.0, -280.0); // Бейдж
        }
        break;
    }
    return matrix;
  }

  @override
  Widget build(BuildContext context) {
    final bool isGoldenState = (_stage == 'result' || _stage == 'expanding') && _currentScore == 10;
    const accentCyan = Color(0xFF00B5E2);
    const accentGold = Color(0xFFFFC629);
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isGoldenState ? accentGold : const Color(0xFF0F172A),
      body: Stack(
        children: [
          // 1. CLEAN BACKGROUND (No Blurs, Minimalist)
          if (!isGoldenState) ...[
            // Орнамент очень тонкий и еле заметный
            Positioned(top: -20, right: -20, child: Opacity(opacity: 0.03, child: _buildOrnament(400))),
            Positioned(bottom: -20, left: -20, child: Opacity(opacity: 0.03, child: _buildOrnament(400))),
          ],

          // 2. ANIMATION CORE
          Positioned.fill(
            child: Center(
              child: AnimatedBuilder(
                animation: _vortexController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: (_stage == 'analyzing' || _stage == 'centering') 
                        ? _vortexController.value * 2 * math.pi 
                        : 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOutCubic, // Более плавная кривая
                      transform: _getSunTransform(),
                      transformAlignment: Alignment.center, 
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: isGoldenState 
                              ? [
                                  BoxShadow(color: accentGold.withOpacity(0.6), blurRadius: 40, spreadRadius: 10),
                                  BoxShadow(color: accentGold.withOpacity(0.4), blurRadius: 80, spreadRadius: 20),
                                ] 
                              : [],
                        ), 
                        // Рисуем чистое векторное солнце без контейнера и теней (для минимализма)
                        child: Center(
                          child: (_stage == 'result' && _currentScore < 10) 
                              ? Text('$_currentScore', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))
                              : CustomPaint(
                                  size: const Size(100, 100), 
                                  painter: KazakhSunPainter(
                                    color: isGoldenState ? const Color(0xFF0F172A).withOpacity(0.2) : accentGold
                                  )
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. MAIN UI (Minimalist)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            top: _stage == 'idle' ? 0 : 800,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Column(
                children: [
                  // Clean Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('QadamGrade', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('AI Assistant', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('KZ', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          // Task Input
                          _buildMinimalInput(
                            label: 'Задание',
                            icon: Icons.description_outlined,
                            activeColor: accentCyan,
                            inputType: _taskInputType,
                            onTypeChange: (v) => setState(() => _taskInputType = v),
                            controller: _taskController,
                            onChanged: (v) => _taskText = v,
                            onPhoto: () => _pickImage(true),
                            images: _taskImages,
                          ),
                          const SizedBox(height: 20),
                          // Answer Input
                          _buildMinimalInput(
                            label: 'Ответ ученика',
                            icon: Icons.edit_note,
                            activeColor: accentGold,
                            inputType: _answerInputType,
                            onTypeChange: (v) => setState(() => _answerInputType = v),
                            controller: _answerController,
                            onChanged: (v) => _studentAnswerText = v,
                            onPhoto: () => _pickImage(false),
                            images: _studentAnswerImages,
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FAB (Minimalist Button)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            bottom: _stage == 'idle' ? 30 : -100,
            left: 24,
            right: 24,
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _handleAnalyze,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentCyan,
                  foregroundColor: Colors.white,
                  elevation: 0, // Flat design
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 20),
                    SizedBox(width: 12),
                    Text('Тексеру', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          // 4. LOADING
          if (_stage == 'analyzing' || _stage == 'centering')
            const Positioned.fill(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 180),
                  child: Text('ANALYZING...', style: TextStyle(fontSize: 14, color: Colors.white24, letterSpacing: 3)),
                ),
              ),
            ),

          // 5. RESULT (Perfect)
          if (_stage == 'result' && _currentScore == 10)
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Spacer(),
                      const Text('10', style: TextStyle(fontSize: 120, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1)),
                      const Text('PERFECT', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 2)),
                      const SizedBox(height: 40),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withOpacity(0.05), // Еле заметная подложка
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: SingleChildScrollView(
                            child: MarkdownBody(
                              data: _evaluationResult,
                              styleSheet: MarkdownStyleSheet(p: const TextStyle(color: Color(0xFF0F172A), fontSize: 16)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _reset,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0F172A), width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('NEXT', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 6. RESULT (Imperfect)
          if (_stage == 'result' && _currentScore < 10)
             Positioned.fill(
               child: DraggableScrollableSheet(
                 initialChildSize: 0.85,
                 minChildSize: 0.8,
                 builder: (context, scrollController) {
                   return Container(
                     decoration: const BoxDecoration(
                       color: Color(0xFF1E293B), // Surface color
                       borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                     ),
                     child: Column(
                       children: [
                         const SizedBox(height: 16),
                         Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
                         Padding(
                           padding: const EdgeInsets.all(24.0),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               const Text('Результат', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                               Text('$_currentScore/10', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white54)),
                             ],
                           ),
                         ),
                         Expanded(
                           child: ListView(
                             controller: scrollController,
                             padding: const EdgeInsets.symmetric(horizontal: 24),
                             children: [
                               _buildResultSection('ЧТО УЛУЧШИТЬ', _evaluationResult, Colors.white70),
                               const SizedBox(height: 40),
                               SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _reset,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('ЗАНОВО', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 40),
                             ],
                           ),
                         ),
                       ],
                     ),
                   );
                 },
               ),
             ),
        ],
      ),
    );
  }

  // --- MINIMALIST COMPONENTS ---

  Widget _buildMinimalInput({
    required String label,
    required IconData icon,
    required Color activeColor,
    required String inputType,
    required Function(String) onTypeChange,
    required TextEditingController controller,
    required Function(String) onChanged,
    required VoidCallback onPhoto,
    required List<String> images,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white54, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), // Surface
            borderRadius: BorderRadius.circular(16),
            // Очень тонкая рамка вместо теней
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              if (inputType == 'text')
                TextField(
                  controller: controller,
                  onChanged: onChanged,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Введите текст...',
                    hintStyle: TextStyle(color: Colors.white24),
                    contentPadding: EdgeInsets.all(20),
                    border: InputBorder.none,
                  ),
                )
              else
                GestureDetector(
                  onTap: onPhoto,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: images.isEmpty 
                        ? Icon(Icons.add_a_photo, color: activeColor.withOpacity(0.5), size: 32)
                        : ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(images.first), fit: BoxFit.cover, width: double.infinity)),
                  ),
                ),
              
              // Minimal Toggle at bottom
              Container(
                height: 1, 
                color: Colors.white.withOpacity(0.05),
              ),
              Row(
                children: [
                  _buildFlatToggle('Текст', inputType == 'text', activeColor, () => onTypeChange('text')),
                  Container(width: 1, height: 20, color: Colors.white.withOpacity(0.05)),
                  _buildFlatToggle('Фото', inputType == 'photo', activeColor, () => onTypeChange('photo')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlatToggle(String text, bool isActive, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            text, 
            style: TextStyle(
              color: isActive ? color : Colors.white24, 
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection(String title, String content, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white24, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        MarkdownBody(data: content, styleSheet: MarkdownStyleSheet(p: TextStyle(color: textColor, fontSize: 16, height: 1.6))),
      ],
    );
  }

  Widget _buildOrnament(double size) {
    return CustomPaint(size: Size(size, size), painter: OrnamentPainter(color: Colors.white));
  }
}