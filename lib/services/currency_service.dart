import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CurrencyService {
  static const String _cacheKey = 'cached_exchange_rates';
  static const String _cacheTimeKey = 'cached_rates_timestamp';
  static const Duration _cacheDuration = Duration(hours: 6); // Match backend update frequency

  // Top 20 currencies
  static const List<Map<String, String>> supportedCurrencies = [
    // Tier 1 - Most common
    {'code': 'VND', 'name': 'Vietnamese Dong', 'symbol': '₫'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
    {'code': 'THB', 'name': 'Thai Baht', 'symbol': '฿'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C\$'},

    // Tier 2 - Additional common
    {'code': 'KRW', 'name': 'South Korean Won', 'symbol': '₩'},
    {'code': 'HKD', 'name': 'Hong Kong Dollar', 'symbol': 'HK\$'},
    {'code': 'TWD', 'name': 'Taiwan Dollar', 'symbol': 'NT\$'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'RM'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'symbol': 'Rp'},
    {'code': 'PHP', 'name': 'Philippine Peso', 'symbol': '₱'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF'},
    {'code': 'NZD', 'name': 'New Zealand Dollar', 'symbol': 'NZ\$'},
    {'code': 'RUB', 'name': 'Russian Ruble', 'symbol': '₽'},
  ];

  /// Fetch latest exchange rates from Supabase
  Future<Map<String, double>> fetchExchangeRates({String base = 'USD'}) async {
    try {
      print('Fetching exchange rates from Supabase for base: $base');

      // Fetch from Supabase
      final response = await Supabase.instance.client
          .from('exchange_rates')
          .select('rates, updated_at')
          .eq('base_currency', 'USD')
          .maybeSingle();

      if (response == null) {
        print('No exchange rates found in Supabase, using fallback');
        return _getFallbackRates(base);
      }

      final ratesData = response['rates'] as Map<String, dynamic>;
      final updatedAt = DateTime.parse(response['updated_at'] as String);

      print('Rates fetched from Supabase, updated at: $updatedAt');
      print('Number of currencies in response: ${ratesData.length}');
      print('Currency codes: ${ratesData.keys.toList()}');

      // Convert USD-based rates to requested base
      final usdRates = <String, double>{};

      // IMPORTANT: Add USD itself to the rates
      usdRates['USD'] = 1.0;

      ratesData.forEach((currency, rate) {
        usdRates[currency] = (rate as num).toDouble();
      });

      print('USD rates loaded: ${usdRates.keys.length} currencies');

      // Convert to requested base currency
      Map<String, double> rates;
      if (base == 'USD') {
        rates = usdRates;
      } else {
        final baseRate = usdRates[base];
        if (baseRate == null) {
          print('Base currency $base not found in rates, using fallback');
          return _getFallbackRates(base);
        }

        print('Converting from USD-based to $base-based rates (baseRate: $baseRate)');

        rates = {};
        usdRates.forEach((currency, rate) {
          rates[currency] = rate / baseRate;
        });

        print('Converted rates for $base base: ${rates.keys.length} currencies');
      }

      // Cache the rates
      await _cacheRates(rates, base);

      return rates;
    } catch (e) {
      print('Error fetching exchange rates from Supabase: $e');
      print('Stack trace: ${StackTrace.current}');
      // Return cached rates if available
      return await _getCachedRates(base) ?? _getFallbackRates(base);
    }
  }

  /// Get exchange rates (cached or fetch new)
  Future<Map<String, double>> getExchangeRates({String base = 'USD'}) async {
    // TEMPORARY: Clear old cache to force refetch with new code
    // TODO: Remove this after first run
    final prefs = await SharedPreferences.getInstance();
    final cacheVersion = prefs.getInt('cache_version') ?? 0;
    if (cacheVersion < 3) {
      print('Clearing old cache (version $cacheVersion)...');
      // Clear all old cache keys
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('cached_exchange_rates') || key.startsWith('cached_rates_timestamp')) {
          await prefs.remove(key);
        }
      }
      await prefs.setInt('cache_version', 3);
    }

    // Check cache first (base-specific)
    final cached = await _getCachedRates(base);
    final cacheTime = await _getCacheTimestamp(base);

    if (cached != null && cacheTime != null) {
      final now = DateTime.now();
      final cacheAge = now.difference(cacheTime);

      if (cacheAge < _cacheDuration) {
        print('Using cached exchange rates for base $base (age: ${cacheAge.inHours}h)');
        print('Cached rates currencies: ${cached.keys.toList()}');
        print('Cached rates count: ${cached.length}');

        // If cache doesn't have enough currencies, refetch
        if (cached.length < 20) {
          print('Cache incomplete (${cached.length} currencies), refetching...');
          return await fetchExchangeRates(base: base);
        }

        return cached;
      }
    }

    // Cache expired or not available, fetch new
    print('Fetching fresh exchange rates for base $base...');
    return await fetchExchangeRates(base: base);
  }

  /// Convert amount from one currency to another
  Future<double> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    if (from == to) return amount;

    final rates = await getExchangeRates(base: from);
    final rate = rates[to];

    if (rate == null) {
      throw Exception('Exchange rate not found for $to');
    }

    return amount * rate;
  }

  /// Get exchange rate between two currencies
  Future<double> getRate({
    required String from,
    required String to,
  }) async {
    if (from == to) return 1.0;

    final rates = await getExchangeRates(base: from);
    final rate = rates[to];

    if (rate == null) {
      throw Exception('Exchange rate not found for $to');
    }

    return rate;
  }

  // Cache management
  Future<void> _cacheRates(Map<String, double> rates, String base) async {
    final prefs = await SharedPreferences.getInstance();
    final ratesJson = json.encode(rates);
    await prefs.setString('${_cacheKey}_$base', ratesJson);
    await prefs.setInt('${_cacheTimeKey}_$base', DateTime.now().millisecondsSinceEpoch);
  }

  Future<Map<String, double>?> _getCachedRates(String base) async {
    final prefs = await SharedPreferences.getInstance();
    final ratesJson = prefs.getString('${_cacheKey}_$base');

    if (ratesJson == null) return null;

    try {
      final data = json.decode(ratesJson) as Map<String, dynamic>;
      return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      return null;
    }
  }

  Future<DateTime?> _getCacheTimestamp(String base) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('${_cacheTimeKey}_$base');

    if (timestamp == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Fallback rates if API fails (approximate, updated manually)
  Map<String, double> _getFallbackRates(String base) {
    // Hardcoded fallback rates (USD base, as of Feb 2026)
    final usdRates = {
      'VND': 25000.0,
      'USD': 1.0,
      'EUR': 0.92,
      'GBP': 0.79,
      'JPY': 145.0,
      'CNY': 7.2,
      'THB': 33.5,
      'SGD': 1.34,
      'AUD': 1.52,
      'CAD': 1.36,
      'KRW': 1320.0,
      'HKD': 7.8,
      'TWD': 31.5,
      'MYR': 4.45,
      'IDR': 15500.0,
      'PHP': 56.0,
      'INR': 83.0,
      'CHF': 0.88,
      'NZD': 1.65,
      'RUB': 92.0,
    };

    if (base == 'USD') {
      return usdRates;
    }

    // Convert to requested base
    final baseRate = usdRates[base] ?? 1.0;
    return usdRates.map((currency, rate) =>
      MapEntry(currency, rate / baseRate)
    );
  }

  /// Get currency symbol
  static String getSymbol(String currencyCode) {
    final currency = supportedCurrencies.firstWhere(
      (c) => c['code'] == currencyCode,
      orElse: () => {'code': currencyCode, 'symbol': currencyCode},
    );
    return currency['symbol'] ?? currencyCode;
  }

  /// Get currency name
  static String getName(String currencyCode) {
    final currency = supportedCurrencies.firstWhere(
      (c) => c['code'] == currencyCode,
      orElse: () => {'code': currencyCode, 'name': currencyCode},
    );
    return currency['name'] ?? currencyCode;
  }
}
