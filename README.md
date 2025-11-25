# QadamGrade

QadamGrade - AI-powered homework evaluation application built with Flutter.

## Features

- **Multi-Photo Support**: Add up to 5 photos for tasks and answers
- **Image Editing**: Crop and draw on images before submission
- **AI Evaluation**: Powered by OpenRouter API using Google's Gemma model
- **Beautiful UI**: Premium Kazakh-themed design with golden animations
- **Perfect Score Animation**: Special golden sun animation for 10/10 scores

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Android Studio / VS Code with Flutter extensions
- OpenRouter API key

### Installation

1. Clone the repository:
```bash
git clone https://github.com/MelonWithGlasses/QadamGrade
cd qadamgrade
```

2. Create a `.env` file in the project root:
```bash
cp .env.example .env
```

3. Add your OpenRouter API key to `.env`:
```
OPENROUTER_API_KEY=your_api_key_here
```

4. Install dependencies:
```bash
flutter pub get
```

5. Run the app:
```bash
flutter run
```

### Building Release APK

```bash
flutter build apk --release
```

The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
lib/
├── main.dart                    # Main app entry point
├── openrouter_service.dart      # OpenRouter API integration
├── image_scanner_service.dart   # Image picker and cropper
├── image_editor_screen.dart     # Drawing screen
└── local_history_service.dart   # Local storage with Hive
```

## Configuration

### Environment Variables

Create a `.env` file with the following variable:

- `OPENROUTER_API_KEY`: Your OpenRouter API key

### API

The app uses OpenRouter's API to evaluate homework. Make sure to:
1. Get an API key from [OpenRouter](https://openrouter.ai/)
2. Add it to your `.env` file
3. Never commit the `.env` file to version control

## Technologies

- **Flutter**: Cross-platform UI framework
- **image_cropper**: Image cropping functionality
- **image_painter**: Drawing on images
- **flutter_dotenv**: Environment variable management
- **Hive**: Local database
- **OpenRouter API**: AI evaluation backend

## License

This project is licensed under the MIT License.

## Made in Kazakhstan 🇰🇿
