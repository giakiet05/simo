import '../models/category.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';

class FuzzySearchService {
  static final Map<String, String> _vietnameseCharMap = {
    'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
    'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
    'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
    'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    'đ': 'd',
  };

  static final RegExp _vietnameseRegex = RegExp(
    r'[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]',
  );

  static final RegExp _shorthandRegex = RegExp(
    r'^([0-9]+(?:\.[0-9]+)?)\s*(k|nghin|nghìn|tr|trieu|triệu|m)$',
    caseSensitive: false,
  );

  /// Chuẩn hóa chuỗi tiếng Việt: chữ thường, bỏ dấu thanh & dấu mũ, loại bỏ khoảng trắng thừa
  String normalizeVietnamese(String input) {
    if (input.trim().isEmpty) return '';
    final lower = input.toLowerCase().trim();
    return lower.replaceAllMapped(_vietnameseRegex, (match) {
      return _vietnameseCharMap[match.group(0)] ?? match.group(0)!;
    });
  }

  /// Phân tích cú pháp chuỗi tìm kiếm số tiền viết tắt hoặc số tiền thông thường
  /// Ví dụ:
  /// - "50k" -> 50000.0
  /// - "1.5tr", "1.5m" -> 1500000.0
  /// - "200nghin", "200 nghìn" -> 200000.0
  /// - "50,000", "50.000", "50000" -> 50000.0
  double? tryParseShorthandAmount(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return null;

    final match = _shorthandRegex.firstMatch(trimmed);
    if (match != null) {
      final numStr = match.group(1);
      final unit = match.group(2);
      final base = double.tryParse(numStr ?? '');
      if (base == null) return null;

      if (unit == 'k' || unit == 'nghin' || unit == 'nghìn') {
        return base * 1000.0;
      } else if (unit == 'tr' || unit == 'trieu' || unit == 'triệu' || unit == 'm') {
        return base * 1000000.0;
      }
    }

    // Kiểm tra định dạng số thông thường có phân cách hàng nghìn (50,000 hoặc 50.000)
    if (RegExp(r'^[0-9]{1,3}(?:[.,][0-9]{3})+$').hasMatch(trimmed)) {
      final sanitized = trimmed.replaceAll(RegExp(r'[.,]'), '');
      return double.tryParse(sanitized);
    }

    // Số thực hoặc số nguyên chuẩn
    return double.tryParse(trimmed);
  }

  /// Xây dựng các biểu diễn ngày tháng phong phú cho một giao dịch để tìm kiếm
  String _buildDateKeywords(DateTime txDate, DateTime now) {
    final d = txDate.day;
    final m = txDate.month;
    final y = txDate.year;

    final dStr = d < 10 ? '0$d' : '$d';
    final mStr = m < 10 ? '0$m' : '$m';

    final dateTokens = [
      '$d/$m/$y',
      '$dStr/$mStr/$y',
      '$d/$m',
      '$dStr/$mStr',
      '$d-$m-$y',
      '$dStr-$mStr-$y',
      '$d-$m',
      '$dStr-$mStr',
      'thang $m',
      'thang $mStr',
      'thang $m/$y',
      'thang $mStr/$y',
      'nam $y',
      '$y',
    ];

    switch (txDate.weekday) {
      case DateTime.monday:
        dateTokens.addAll(['thu hai', 'thu 2', 't2']);
        break;
      case DateTime.tuesday:
        dateTokens.addAll(['thu ba', 'thu 3', 't3']);
        break;
      case DateTime.wednesday:
        dateTokens.addAll(['thu tu', 'thu 4', 't4']);
        break;
      case DateTime.thursday:
        dateTokens.addAll(['thu nam', 'thu 5', 't5']);
        break;
      case DateTime.friday:
        dateTokens.addAll(['thu sau', 'thu 6', 't6']);
        break;
      case DateTime.saturday:
        dateTokens.addAll(['thu bay', 'thu 7', 't7']);
        break;
      case DateTime.sunday:
        dateTokens.addAll(['chu nhat', 'cn']);
        break;
    }

    final isToday = txDate.year == now.year && txDate.month == now.month && txDate.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = txDate.year == yesterday.year && txDate.month == yesterday.month && txDate.day == yesterday.day;
    final dayBeforeYesterday = now.subtract(const Duration(days: 2));
    final isDayBefore = txDate.year == dayBeforeYesterday.year && txDate.month == dayBeforeYesterday.month && txDate.day == dayBeforeYesterday.day;

    if (isToday) {
      dateTokens.add('hom nay');
    }
    if (isYesterday) {
      dateTokens.add('hom qua');
    }
    if (isDayBefore) {
      dateTokens.add('hom kia');
    }

    return dateTokens.join(' ');
  }

  /// Tìm kiếm giao dịch đa trường (Ghi chú, Danh mục, Tên ví, Số tiền, Ngày tháng)
  /// Giữ nguyên thứ tự danh sách ban đầu (đã được sắp xếp theo ngày giảm dần)
  List<Transaction> search({
    required List<Transaction> transactions,
    required String query,
    required Map<String, Category> categoryMap,
    required Map<String, Wallet> walletMap,
    DateTime? currentTime,
  }) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return transactions;
    }

    final now = currentTime ?? DateTime.now();
    final normQuery = normalizeVietnamese(trimmedQuery);
    final queryTokens = normQuery.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final shorthandAmount = tryParseShorthandAmount(trimmedQuery);

    return transactions.where((tx) {
      // 1. Khớp số tiền viết tắt hoặc số tiền chính xác khi toàn bộ query là tiền
      if (shorthandAmount != null) {
        if ((tx.amount - shorthandAmount).abs() < 0.01) {
          return true;
        }
      }

      // 2. Chuẩn bị các trường văn bản và ngày tháng để khớp
      final noteNorm = tx.note != null ? normalizeVietnamese(tx.note!) : '';
      final catName = tx.categoryId != null && categoryMap.containsKey(tx.categoryId)
          ? normalizeVietnamese(categoryMap[tx.categoryId]!.name)
          : '';
      final walletName = tx.walletId != null && walletMap.containsKey(tx.walletId)
          ? normalizeVietnamese(walletMap[tx.walletId]!.name)
          : '';
      final amountStr = tx.amount.toInt().toString();
      final dateKeywords = _buildDateKeywords(tx.transactionDate, now);

      final combinedTarget = '$noteNorm $catName $walletName $amountStr $dateKeywords';

      // 3. Khớp cụm từ chính xác nếu query có nhiều từ
      if (normQuery.contains(' ') && combinedTarget.contains(normQuery)) {
        return true;
      }

      // 4. Khớp các từ khóa (tokens)
      final targetWords = combinedTarget.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (queryTokens.isNotEmpty && queryTokens.every((token) {
        // Kiểm tra nếu token là số tiền viết tắt (ví dụ "50k", "1.5tr")
        final tokenAmount = tryParseShorthandAmount(token);
        if (tokenAmount != null && (tx.amount - tokenAmount).abs() < 0.01) {
          return true;
        }

        // Kiểm tra nếu token là ngày tháng có chứa dấu gạch (ví dụ: "4/9", "04/09", "4-9")
        if (token.contains('/') || token.contains('-')) {
          if (combinedTarget.contains(token)) {
            return true;
          }
        }

        // Khớp theo tiền tố từ hoặc từ hoàn chỉnh
        return targetWords.any((w) =>
            w == token ||
            w.startsWith(token) ||
            (token.length >= 3 && w.contains(token) && w.length >= 6));
      })) {
        return true;
      }

      return false;
    }).toList();
  }
}
