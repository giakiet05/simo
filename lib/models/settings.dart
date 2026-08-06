class Settings {
  final double monthlyBudget;
  final String currency;
  final String language;
  final String themeMode;

  Settings({
    required this.monthlyBudget,
    required this.currency,
    required this.language,
    required this.themeMode,
  });

  Settings copyWith({
    double? monthlyBudget,
    String? currency,
    String? language,
    String? themeMode,
  }) {
    return Settings(
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'monthlyBudget': monthlyBudget,
      'currency': currency,
      'language': language,
      'themeMode': themeMode,
    };
  }

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      monthlyBudget: (map['monthlyBudget'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'VND',
      language: map['language'] as String? ?? 'vi',
      themeMode: map['themeMode'] as String? ?? 'system',
    );
  }
}
