import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageScannerService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<String> scanImage() async {
    try {
      XFile? image;
      
      if (kIsWeb) {
        image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
      } else {
        image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
      }

      if (image == null) {
        return '';
      }

      if (!kIsWeb) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Кадрирование',
              toolbarColor: const Color(0xFF0F172A),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Кадрирование',
            ),
          ],
        );
        
        if (croppedFile != null) {
          return croppedFile.path;
        }
      }
      
      return image.path;
    } catch (e) {
      throw Exception('Ошибка выбора изображения: $e');
    }
  }

  void dispose() {
    // Nothing to dispose since we're not using ML Kit anymore
  }
}