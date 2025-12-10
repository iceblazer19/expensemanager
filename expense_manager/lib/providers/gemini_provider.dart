import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_item.dart';

class GeminiProvider extends ChangeNotifier {
  final String apiKey;

  GeminiProvider(this.apiKey);

  bool _loading = false;
  String? _advice;
  String? _error;

  bool get loading => _loading;
  String? get advice => _advice;
  String? get error => _error;

  Future<void> fetchFinancialAdvice(List<TransactionItem> items) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );

    final transactionsText = items.map((t) {
      return """
{
  id: "${t.id}",
  title: "${t.title}",
  amount: ${t.amount},
  date: "${t.date.toIso8601String()}",
  isIncome: ${t.isIncome},
  category: "${t.category}"
}
""";
    }).join(",\n");

    final prompt = """
Berikut adalah data transaksi keuangan saya:

$transactionsText

Berikan saya analisis keuangan komprehensif berdasarkan data tersebut.
Fokus pada:
- Pola pengeluaran berdasarkan kategori
- Keseimbangan income vs expense
- Kategori yang boros
- Potensi kebocoran
- Saran penghematan paling efektif
- Rekomendasi alokasi dana
- Perubahan kebiasaan yang disarankan

Tuliskan ringkas, jelas, actionable, dalam Bahasa Indonesia.
""";

    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    };

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final output = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

        _advice = output ?? "Tidak ada saran dari AI.";
      } else {
        print("Gemini API Error: ${res.statusCode}");
        print("Response body: ${res.body}");
        _error = "Gagal mengambil saran (status ${res.statusCode}).";
      }
    } catch (e) {
      _error = "Terjadi kesalahan: $e";
    }

    _loading = false;
    notifyListeners();
  }

  void clear() {
    _advice = null;
    _error = null;
    notifyListeners();
  }
}
