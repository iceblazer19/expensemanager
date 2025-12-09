import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_manager/models/transaction_item.dart';

class TransactionTile extends StatelessWidget {
  final TransactionItem item;
  const TransactionTile({required this.item, super.key});

  static final NumberFormat _rupiahFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  String _formatAmount(num value) {
    final abs = value.abs().toDouble();
    return _rupiahFormatter.format(abs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Amount pill colors
    final Color incomeBg = isDark ? const Color(0xFF163D2E) : const Color(0xFFE6F4EA);
    final Color expenseBg = isDark ? const Color(0xFF3D1515) : const Color(0xFFFDECEA);
    final Color incomeText = isDark ? const Color(0xFF8CE08B) : const Color(0xFF15643A);
    final Color expenseText = isDark ? const Color(0xFFF49B9B) : const Color(0xFFB22222);

    final bool isIncome = item.isIncome;
    final amtText = _formatAmount(item.amount ?? 0);

    // Date formatting
    final dateText = (() {
      try {
        final d = item.date;
        if (d is DateTime) {
          return DateFormat('dd/MM/yyyy').format(d);
        }
      } catch (_) {}
      return '';
    })();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
      child: Card(
        color: theme.cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading icon circle
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: isIncome
                      ? (isDark ? Colors.green.withOpacity(0.12) : Colors.green[50])
                      : (isDark ? Colors.red.withOpacity(0.12) : Colors.red[50]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome ? Colors.green : Colors.red,
                    size: 22,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Subtitle: category · date
                    Text(
                      '${item.category ?? ''}${(item.category != null && dateText.isNotEmpty) ? ' · ' : ''}$dateText',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Amount pill (single line)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isIncome ? incomeBg : expenseBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${isIncome ? '+' : '-'} $amtText',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isIncome ? incomeText : expenseText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}