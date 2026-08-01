import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../services/ai_transaction_service.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as tx_model;

class VoiceRecordSheet extends ConsumerStatefulWidget {
  const VoiceRecordSheet({super.key});

  @override
  ConsumerState<VoiceRecordSheet> createState() => _VoiceRecordSheetState();
}

class _VoiceRecordSheetState extends ConsumerState<VoiceRecordSheet> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isProcessing = false;
  String _text = 'Bấm vào micro và bắt đầu nói...';
  final AiTransactionService _aiService = AiTransactionService();
  Timer? _countdownTimer;
  int _remainingSeconds = 5;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _processAi() async {
    if (_text.isEmpty || _text == 'Bấm vào micro và bắt đầu nói...') return;
    if (_isProcessing) return; // Tránh gọi nhiều lần khi status nhảy liên tục
    
    setState(() {
      _isProcessing = true;
    });

    final categories = ref.read(categoryProvider).value ?? [];
    
    final result = await _aiService.parseTransaction(_text, categories);
    
    if (result != null && mounted) {
      try {
        final transactionsData = result['transactions'] as List<dynamic>;
        if (transactionsData.isEmpty) {
          throw Exception("Không tìm thấy giao dịch nào.");
        }

        final List<Map<String, dynamic>> newTransactions = [];

        for (var txData in transactionsData) {
          final amount = (txData['amount'] as num).toDouble();
          final type = txData['type'] as String;
          final note = txData['note'] as String?;
          final categoryId = txData['categoryId'] as String?;
          final dateStr = txData['date'] as String?;
          final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

          newTransactions.add({
            'categoryId': categoryId,
            'amount': amount,
            'note': note,
            'type': type,
          });
        }

        await ref.read(transactionProvider.notifier).createTransactions(newTransactions);
        
        if (mounted) {
          Navigator.pop(context); // Đóng sheet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm giao dịch thành công!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        setState(() {
          _text = 'Lỗi xử lý dữ liệu AI: $e';
          _isProcessing = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _text = 'Không thể phân tích câu nói. Vui lòng thử lại!';
          _isProcessing = false;
        });
      }
    }
  }

  void _resetSilenceTimer() {
    _countdownTimer?.cancel();
    if (_isListening) {
      setState(() {
        _remainingSeconds = 5;
      });
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || !_isListening) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          }
        });
        if (_remainingSeconds == 0) {
          timer.cancel();
          print('Silence timeout triggered!');
          _speech.stop();
          setState(() => _isListening = false);
          if (_text.isNotEmpty && _text != 'Bấm vào micro và bắt đầu nói...') {
            _processAi();
          }
        }
      });
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        print('onStatus: $val');
        if (val == 'done' || val == 'notListening') {
          if (mounted) {
            _countdownTimer?.cancel();
            setState(() => _isListening = false);
            if (_text.isNotEmpty && _text != 'Bấm vào micro và bắt đầu nói...') {
              _processAi();
            }
          }
        }
      },
      onError: (val) => print('onError: $val'),
    );
    if (available) {
      if (mounted) {
        setState(() {
          _isListening = true;
          _text = '';
        });
      }
      _resetSilenceTimer();
      _speech.listen(
        onResult: (val) {
          if (mounted) {
            setState(() {
              _text = val.recognizedWords;
            });
            _resetSilenceTimer();
          }
        },
        localeId: 'vi_VN',
        listenFor: const Duration(seconds: 30),
      );
    } else {
      var status = await Permission.microphone.request();
      if (status.isDenied) {
        if (mounted) setState(() => _text = 'Vui lòng cấp quyền Micro để sử dụng.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch để ép provider load data từ DB lên ngay khi mở sheet
    ref.watch(categoryProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      height: 350,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Nhận diện giọng nói',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: _isProcessing 
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const Text('AI đang phân tích...'),
                      Text('"$_text"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                    ],
                  )
                : Text(
                    _text,
                    style: const TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
            ),
          ),
          if (!_isProcessing)
            GestureDetector(
              onTap: () {
                if (_isProcessing) return;
                if (_isListening) {
                  // Tắt mic và xử lý luôn
                  setState(() => _isListening = false);
                  _speech.stop();
                  _processAi();
                } else {
                  _startListening();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isListening ? 100 : 80,
                width: _isListening ? 100 : 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? Colors.red : Theme.of(context).colorScheme.primary,
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ]
                      : [],
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (!_isProcessing)
            Text(
              _isListening ? 'Đang nghe... (Tự ngắt sau $_remainingSeconds giây)' : 'Chạm vào micro để nói',
              style: TextStyle(color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }
}
