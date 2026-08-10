import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'speech_recognition_service.dart';

class LocalSpeechToTextService implements SpeechRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<bool> initialize({
    required Function(String status) onStatus,
    required Function(String error) onError,
  }) async {
    bool available = await _speech.initialize(
      onStatus: onStatus,
      onError: (e) => onError(e.errorMsg),
    );
    
    if (!available) {
      var status = await Permission.microphone.request();
      if (status.isDenied) {
        onError('Vui lòng cấp quyền Micro để sử dụng.');
      }
    }
    
    return available;
  }

  @override
  Future<bool> startListening({
    required Function(String text) onResult,
    required Duration listenFor,
  }) async {
    if (!_speech.isAvailable) return false;

    await _speech.listen(
      onResult: (val) {
        onResult(val.recognizedWords);
      },
      localeId: 'vi_VN',
      listenFor: listenFor,
    );
    return true;
  }

  @override
  Future<void> stop() async {
    await _speech.stop();
  }

  @override
  Future<void> cancel() async {
    await _speech.cancel();
  }
}
