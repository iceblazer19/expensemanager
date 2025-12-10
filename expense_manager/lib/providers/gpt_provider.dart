import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_item.dart';

class GPTProvider extends ChangeNotifier {
  final String gptApiKey;

  GPTProvider({
    required this.gptApiKey,
  });

  bool _loading = false;
  String? _advice;
  String? _error;

  bool get loading => _loading;
  String? get advice => _advice;
  String? get error => _error;

  String _prompt2(List<TransactionItem> items) {

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
Anda adalah analis keuangan profesional. Berikut data transaksi saya:

$transactionsText

Berikan rekomendasi dan analisis menyeluruh:
- Tren pengeluaran
- Analisis kategori
- Rasio income vs expense
- Pemborosan terbesar
- Prioritas penghematan
- Rekomendasi budgeting
- Saran gaya hidup finansial

Jawab dengan Bahasa Indonesia yang ringkas dan actionable.
""";
    return prompt;
  }

  String _buildPrompt(List<TransactionItem> tx) {
    final income = tx.where((e) => e.isIncome).fold(0.0, (a, b) => a + b.amount);
    final expense = tx.where((e) => !e.isIncome).fold(0.0, (a, b) => a + b.amount);

    final expenseList = tx
        .where((e) => !e.isIncome)
        .map((e) => "- ${e.category}: ${e.title} (${e.amount}) pada ${e.date}")
        .join("\n");

    return """
Analisis keuangan berikut dan berikan saran **singkat** (maksimal 6-10 kalimat).
Fokus pada insight inti, prioritas utama, dan rekomendasi yang bisa langsung diterapkan.

Total Income: $income
Total Expense: $expense

Rincian pengeluaran:
$expenseList

Berikan jawaban ringkas namun tajam dalam bahasa Indonesia.
""";
  }

  Future<void> fetchAdvice(List<TransactionItem> items) async {
    _loading = true;
    _error = null;
    _advice = null;
    notifyListeners();

    final gptUrl = Uri.parse("https://api.openai.com/v1/chat/completions");

    final gptBody = {
      "model": "gpt-4o-mini",
      "messages": [
        {"role": "user", "content": _buildPrompt(items)}
      ],
      "temperature": 0.5
    };

    try {
      final response = await http.post(
        gptUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $gptApiKey",
        },
        body: jsonEncode(gptBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data["choices"]?[0]?["message"]?["content"] ?? "Tidak ada respons GPT.";

        _advice = content;
        _loading = false;
      } else {
        // Print full error response for debugging
        print("OpenAI API Error: ${response.statusCode}");
        print("Response body: ${response.body}");
        _error = "Gagal mengambil saran (status ${response.statusCode}).";
        _loading = false;
      }
    } catch (e) {
      _error = "Terjadi kesalahan: $e";
      _loading = false;
    }

    notifyListeners();
  }

  void clear() {
    _advice = null;
    _error = null;
    notifyListeners();
  }
}
