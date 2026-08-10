import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'speech_recognition_service.dart';
import 'local_speech_service.dart';
import 'whisper_speech_service.dart';

class SpeechServiceFactory {
  static SpeechRecognitionService create() {
    final useWhisper = dotenv.env['USE_WHISPER']?.toLowerCase() == 'true';
    if (useWhisper) {
      return WhisperSpeechService();
    } else {
      return LocalSpeechToTextService();
    }
  }
}
