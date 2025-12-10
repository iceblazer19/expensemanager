import 'package:flutter/foundation.dart';
import '../models/transaction_item.dart';
import 'gemini_provider.dart';
import 'gpt_provider.dart';

/// Combined AI provider that tries Gemini first, then falls back to GPT if it fails
class CombinedAIProvider extends ChangeNotifier {
  final GeminiProvider _geminiProvider;
  final GPTProvider _gptProvider;

  CombinedAIProvider({
    required String geminiApiKey,
    required String gptApiKey,
  })  : _geminiProvider = GeminiProvider(geminiApiKey),
        _gptProvider = GPTProvider(gptApiKey: gptApiKey);

  bool _loading = false;
  String? _advice;
  String? _error;
  String? _usedProvider; // Track which provider was used

  bool get loading => _loading;
  String? get advice => _advice;
  String? get error => _error;
  String? get usedProvider => _usedProvider;

  /// Fetch advice with automatic fallback
  /// Tries Gemini first, falls back to GPT if Gemini fails
  Future<void> fetchAdviceWithFallback(List<TransactionItem> items) async {
    _loading = true;
    _error = null;
    _advice = null;
    _usedProvider = null;
    notifyListeners();

    // Try Gemini first
    try {
      print('Trying Gemini API...');
      await _geminiProvider.fetchFinancialAdvice(items);
      
      if (_geminiProvider.advice != null) {
        _advice = _geminiProvider.advice;
        _usedProvider = 'Gemini';
        _loading = false;
        print('✓ Gemini API succeeded');
        notifyListeners();
        return;
      }
    } catch (e) {
      print('✗ Gemini API failed: $e');
    }

    // If Gemini failed, try GPT
    try {
      print('Falling back to GPT API...');
      await _gptProvider.fetchAdvice(items);
      
      if (_gptProvider.advice != null) {
        _advice = _gptProvider.advice;
        _usedProvider = 'GPT';
        _loading = false;
        print('✓ GPT API succeeded');
        notifyListeners();
        return;
      }
    } catch (e) {
      print('✗ GPT API failed: $e');
    }

    // Both failed
    _error = 'Kedua AI (Gemini dan GPT) gagal memberikan saran. Silakan coba lagi nanti.';
    _loading = false;
    notifyListeners();
  }

  void clear() {
    _advice = null;
    _error = null;
    _usedProvider = null;
    _geminiProvider.clear();
    _gptProvider.clear();
    notifyListeners();
  }
}
