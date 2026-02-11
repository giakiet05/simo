class Settings {
  final double monthlyBudget;
  final String currency;
  final String language;

  Settings({
    required this.monthlyBudget,
    required this.currency,
    required this.language,
  });

  Settings copyWith({
    double? monthlyBudget,
    String? currency,
    String? language,
  }) {
    return Settings(
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      currency: currency ?? this.currency,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'monthlyBudget': monthlyBudget,
      'currency': currency,
      'language': language,
    };
  }

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      monthlyBudget: (map['monthlyBudget'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'VND',
      language: map['language'] as String? ?? 'vi',
    );
  }
}
