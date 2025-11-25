import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_painter/image_painter.dart';
import 'package:path_provider/path_provider.dart';

class ImageEditorScreen extends StatefulWidget {
  final String imagePath;

  const ImageEditorScreen({super.key, required this.imagePath});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  final _imageKey = GlobalKey<ImagePainterState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Редактор"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveImage,
          )
        ],
      ),
      body: ImagePainter.file(
        File(widget.imagePath),
        key: _imageKey,
        scalable: true,
        initialStrokeWidth: 2,
        initialColor: Colors.red,
        controlsAtTop: false,
      ),
    );
  }

  Future<void> _saveImage() async {
    final image = await _imageKey.currentState?.exportImage();
    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.png';
      final fullPath = '${directory.path}/$fileName';
      final imgFile = File(fullPath);
      await imgFile.writeAsBytes(image);
      if (mounted) {
        Navigator.pop(context, fullPath);
      }
    }
  }
}
