import 'package:flutter/foundation.dart';

abstract class SpeechRecognitionService {
  /// Khởi tạo service (ví dụ xin quyền)
  Future<bool> initialize({
    required Function(String status) onStatus,
    required Function(String error) onError,
  });

  /// Bắt đầu lắng nghe (hoặc ghi âm). 
  /// Trả về true nếu bắt đầu thành công.
  Future<bool> startListening({
    required Function(String text) onResult,
    required Duration listenFor,
  });

  /// Dừng lắng nghe và xử lý (nếu đang ghi âm thì sẽ ngừng và gửi API)
  Future<void> stop();

  /// Hủy bỏ quá trình lắng nghe hiện tại mà không xử lý
  Future<void> cancel();

  /// Kiểm tra xem có đang lắng nghe không
  bool get isListening;
}
