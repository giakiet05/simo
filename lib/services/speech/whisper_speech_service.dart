import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'speech_recognition_service.dart';

class WhisperSpeechService implements SpeechRecognitionService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _filePath;
  Function(String)? _onStatus;
  Function(String)? _onError;
  Function(String)? _onResult;

  @override
  bool get isListening => _isRecording;

  @override
  Future<bool> initialize({
    required Function(String status) onStatus,
    required Function(String error) onError,
  }) async {
    _onStatus = onStatus;
    _onError = onError;
    
    if (await _audioRecorder.hasPermission()) {
      return true;
    } else {
      var status = await Permission.microphone.request();
      if (status.isDenied) {
        onError('Vui lòng cấp quyền Micro để sử dụng.');
        return false;
      }
      return await _audioRecorder.hasPermission();
    }
  }

  @override
  Future<bool> startListening({
    required Function(String text) onResult,
    required Duration listenFor,
  }) async {
    try {
      _onResult = onResult;
      
      final tempDir = await getTemporaryDirectory();
      _filePath = '${tempDir.path}/whisper_record.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _filePath!,
      );
      
      _isRecording = true;
      _onStatus?.call('listening');
      return true;
    } catch (e) {
      _onError?.call('Lỗi ghi âm: $e');
      return false;
    }
  }

  @override
  Future<void> stop() async {
    if (!_isRecording) return;
    
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      
      if (path != null && _onResult != null) {
        _onStatus?.call('processing');
        // Send to Groq Whisper API
        await _transcribeAudio(path);
      }
      _onStatus?.call('done');
    } catch (e) {
      _onError?.call('Lỗi khi dừng ghi âm: $e');
    }
  }

  @override
  Future<void> cancel() async {
    if (!_isRecording) return;
    
    try {
      await _audioRecorder.stop();
      _isRecording = false;
      _onStatus?.call('notListening');
    } catch (e) {
      print('Lỗi hủy ghi âm: $e');
    }
  }

  Future<void> _transcribeAudio(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        _onError?.call('File ghi âm không tồn tại.');
        return;
      }

      final apiKey = dotenv.env['WHISPER_API_KEY'] ?? dotenv.env['AI_API_KEY'] ?? '';
      final baseUrl = dotenv.env['WHISPER_BASE_URL'] ?? dotenv.env['AI_BASE_URL'] ?? 'https://api.groq.com/openai/v1';
      final endpoint = baseUrl.endsWith('/audio/transcriptions') 
          ? baseUrl 
          : '${baseUrl.replaceAll(RegExp(r"/chat/completions$"), "")}/audio/transcriptions';

      var request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.headers.addAll({
        'Authorization': 'Bearer $apiKey',
      });
      
      request.fields['model'] = dotenv.env['WHISPER_MODEL'] ?? 'whisper-large-v3';
      request.fields['language'] = 'vi';
      // Gợi ý ngữ cảnh cho Whisper để dịch chuẩn xác hơn các từ lóng tiền tệ Việt Nam
      request.fields['prompt'] = 'Các giao dịch thu chi tài chính bằng tiếng Việt: k, ka, ca, ngàn, nghìn, cành, vạn, chục, lít, xị, củ, triệu, ăn sáng 70k, đi nhậu 1 củ, đổ xăng năm chục, cà phê 35 ka.';

      request.files.add(await http.MultipartFile.fromPath('file', path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final text = data['text'] ?? '';
        _onResult?.call(text);
      } else {
        _onError?.call('Lỗi API Whisper: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      _onError?.call('Lỗi khi gọi API Whisper: $e');
    }
  }
}
