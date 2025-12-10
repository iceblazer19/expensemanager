import 'package:expense_manager/providers/gemini_provider.dart';
import 'package:expense_manager/providers/gpt_provider.dart';
import 'package:expense_manager/providers/combined_ai_provider.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_manager/providers/transaction_provider.dart';
import 'package:expense_manager/providers/theme_provider.dart';
import 'package:expense_manager/widgets/add_transaction_form.dart';
import 'package:expense_manager/widgets/transaction_tile.dart';
import 'package:expense_manager/models/transaction_item.dart';

enum FilterType { all, income, expense }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FilterType _filter = FilterType.all;
  int _daysFilter = 0;

  final List<Map<String, int>> _dateOptions = const [
    {'1 Day': 1},
    {'3 Days': 3},
    {'7 Days': 7},
    {'30 Days': 30},
    {'356 Days': 356},
    {'All': 0},
  ];

  // Intl formatter for Indonesian Rupiah (no decimals)
  final NumberFormat _rupiahFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  List<TransactionItem> filteredItems(List<TransactionItem> items) {
    var results = items;
    switch (_filter) {
      case FilterType.income:
        results = results.where((t) => t.isIncome).toList();
        break;
      case FilterType.expense:
        results = results.where((t) => !t.isIncome).toList();
        break;
      case FilterType.all:
      default:
        break;
    }

    if (_daysFilter > 0) {
      final cutoff = DateTime.now().subtract(Duration(days: _daysFilter));
      results = results.where((t) {
        try {
          final d = t.date;
          if (d is DateTime) return d.isAfter(cutoff);
        } catch (_) {}
        return false;
      }).toList();
    }

    return results;
  }

  // formatCurrency now uses intl and returns Rupiah with no decimals
  String formatCurrency(double amount) {
    return _rupiahFormatter.format(amount.abs());
  }

  void _showAddSheet(BuildContext context, {bool initialIsIncome = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: AddTransactionForm(initialIsIncome: initialIsIncome),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String label, String amountText, Color leftColor, IconData icon,
      {Color? textColor}) {
    return Expanded(
      child: Semantics(
        container: true,
        label: '$label summary',
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [leftColor.withOpacity(0.95), leftColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor ?? Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = _daysFilter == 0
        ? 'All'
        : _dateOptions.firstWhere((m) => m.values.first == _daysFilter, orElse: () => {'All': 0}).keys.first;
    final popupColor = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03);

    return PopupMenuButton<int>(
      initialValue: _daysFilter,
      tooltip: 'Filter by date',
      color: popupColor,
      elevation: 4,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (int days) {
        setState(() {
          _daysFilter = days;
        });
      },
      itemBuilder: (context) {
        return _dateOptions.map((entry) {
          final label = entry.keys.first;
          final value = entry.values.first;
          return PopupMenuItem<int>(
            value: value,
            child: Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseAI(GPTProvider aiprovider) {
    return Stack(
      children: [
        if (aiprovider.loading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),

        if (aiprovider.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                aiprovider.error!,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
          ),

        if (aiprovider.advice != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.psychology_alt, color: Colors.amber.shade800),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      aiprovider.advice!,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),

      ],
    );
  }

  void _showAIAdvicePopup(BuildContext context, String advice) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(
              maxHeight: 500,
              minWidth: 300,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Saran Keuangan AI",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: SingleChildScrollView(
                    child: GptMarkdown(
                      advice,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Tutup"),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final items = filteredItems(provider.items);
    final gpt = Provider.of<GPTProvider>(context);

    // compute date-filtered totals (no decimals)
    final List<TransactionItem> dateFiltered = (_daysFilter > 0)
        ? provider.items.where((t) {
            try {
              final d = t.date;
              if (d is DateTime) return d.isAfter(DateTime.now().subtract(Duration(days: _daysFilter)));
            } catch (_) {}
            return false;
          }).toList()
        : provider.items.toList();

    double incomeTotal = dateFiltered.where((t) => t.isIncome).fold(0.0, (double s, t) {
      final a = (t.amount is num) ? (t.amount as num).toDouble() : 0.0;
      return s + a;
    });

    double expenseTotal = dateFiltered.where((t) => !t.isIncome).fold(0.0, (double s, t) {
      final a = (t.amount is num) ? (t.amount as num).toDouble() : 0.0;
      return s + a;
    });

    // header gradient (keeps previous palettes)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lightGradientStart = const Color(0xFF475C7A);
    final lightGradientEnd = const Color(0xFFF0B86D);
    final darkGradientStart = const Color(0xFF141516);
    final darkGradientMid = const Color(0xFF2A2F31);
    final darkGradientEnd = const Color(0xFF3A2B2D);

    final gradient = isDark
        ? LinearGradient(colors: [darkGradientStart, darkGradientMid, darkGradientEnd], begin: Alignment.centerLeft, end: Alignment.centerRight, stops: const [0.0, 0.55, 1.0])
        : LinearGradient(colors: [lightGradientStart, lightGradientEnd], begin: Alignment.centerLeft, end: Alignment.centerRight);

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Container(
              height: 88,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  const Icon(Icons.pie_chart_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Expense Manager',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: InkResponse(
                      onTap: () => themeProvider.toggleTheme(),
                      radius: 24,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(scale: animation, child: child),
                            );
                          },
                          child: Icon(
                            themeProvider.isDark ? Icons.nightlight_round : Icons.wb_sunny,
                            key: ValueKey<bool>(themeProvider.isDark),
                            color: Colors.white,
                            size: 20,
                            semanticLabel: themeProvider.isDark ? 'Dark mode' : 'Light mode',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddSheet(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Transaction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Row(
                  key: ValueKey('${incomeTotal}-${expenseTotal}-${_daysFilter}'),
                  children: [
                    _buildSummaryCard('Income', '+ ${formatCurrency(incomeTotal)}', Colors.green, Icons.trending_up, textColor: Colors.green[800]),
                    const SizedBox(width: 12),
                    _buildSummaryCard('Expenses', '- ${formatCurrency(expenseTotal)}', Colors.red, Icons.trending_down, textColor: Colors.red[800]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: Consumer<CombinedAIProvider>(
                  builder: (context, aiProvider, _) {
                    return ElevatedButton(
                      onPressed: aiProvider.loading
                          ? null
                          : () async {
                        await aiProvider.fetchAdviceWithFallback(provider.items);
                        if (aiProvider.advice != null && context.mounted) {
                          // Show which AI was used
                          final usedAI = aiProvider.usedProvider ?? 'AI';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Saran dari $usedAI'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          _showAIAdvicePopup(context, aiProvider.advice!);
                        } else if (aiProvider.error != null && context.mounted) {
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${aiProvider.error}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      },
                      child: aiProvider.loading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text("Dapatkan Saran AI"),
                    );
                  },
                )
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _filter == FilterType.all,
                    onSelected: (_) => setState(() => _filter = FilterType.all),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Income'),
                    selected: _filter == FilterType.income,
                    onSelected: (_) => setState(() => _filter = FilterType.income),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Expenses'),
                    selected: _filter == FilterType.expense,
                    onSelected: (_) => setState(() => _filter = FilterType.expense),
                  ),
                  const Spacer(),
                  _buildDateFilterMenu(),
                ],
              ),
            ),

            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text('No transactions', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                          const SizedBox(height: 6),
                          Text('Tap Add Transaction to create a new entry', style: TextStyle(color: Colors.grey[500]), textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) => TransactionTile(item: items[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}