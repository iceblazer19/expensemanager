import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_manager/providers/transaction_provider.dart';
import 'package:expense_manager/models/transaction_item.dart';

class AddTransactionForm extends StatefulWidget {
  final bool initialIsIncome;
  const AddTransactionForm({this.initialIsIncome = false, super.key});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isIncome = false;

  // Restore the category lists (these were the arrays shown in your screenshot)
  static const List<String> _incomeCategories = [
    'Salary',
    'Bonus',
    'Freelance',
    'Investment',
    'Interest',
    'Refund',
    'Gift',
    'Dividends',
    'Rental Income',
    'Other Income',
  ];

  static const List<String> _expenseCategories = [
    'Food',
    'Groceries',
    'Bills',
    'Rent',
    'Utilities',
    'Transportation',
    'Healthcare',
    'Shopping',
    'Entertainment',
    'Subscriptions',
    'Taxes',
    'Education',
    'Travel',
    'Gifts',
    'Pet',
    'Home',
    'Loan Payment',
    'Other Expense',
  ];

  // getter to pick the right list
  List<String> get _currentCategories => _isIncome ? _incomeCategories : _expenseCategories;

  // selected category
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _isIncome = widget.initialIsIncome;
    // default category when form opens
    _selectedCategory = _currentCategories.isNotEmpty ? _currentCategories.first : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;

    final item = TransactionItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      isIncome: _isIncome,
      category: _selectedCategory ?? (_isIncome ? 'Other Income' : 'Other Expense'),
      date: DateTime.now(),
    );

    // Using provider to add transaction (adjust if your provider API differs)
    Provider.of<TransactionProvider>(context, listen: false).addTransaction(item);

    Navigator.of(context).pop();
  }

  InputDecoration _fieldDecoration({
    required BuildContext context,
    required Widget prefix,
    String? hint,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use small, contrasting prefix background depending on theme so icon is always visible
    final prefixBg = isDark ? Colors.white12 : Colors.black.withOpacity(0.06);
    final iconColor = isDark ? Colors.white : Colors.black87;

    return InputDecoration(
      hintText: hint,
      hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 8.0),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: prefixBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: IconTheme(data: IconThemeData(color: iconColor, size: 18), child: prefix)),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 40),
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Opens a centered dialog with a search field + filtered category list.
  // Using a dialog avoids the dropdown overlay overlapping the bottom "Add" button.
  Future<void> _openCategoryPicker() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final List<String> source = _currentCategories;
    String search = '';
    String? picked = _selectedCategory;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        // Use StatefulBuilder to manage local search state inside the dialog.
        return StatefulBuilder(builder: (context, setStateDialog) {
          final filtered = source.where((c) => c.toLowerCase().contains(search.toLowerCase())).toList();

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 420, // cap height so it doesn't cover everything
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.dialogBackgroundColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Text(
                      'Select category',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),

                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search categories...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (value) {
                        setStateDialog(() {
                          search = value;
                        });
                      },
                    ),
                  ),

                  // List (no dividing lines)
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text('No results', style: theme.textTheme.bodyMedium))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final c = filtered[i];
                              final selected = c == picked;
                              return ListTile(
                                title: Text(c),
                                dense: true,
                                // remove any separators by not using Dividers or separators
                                // keep a subtle tile color on selection only
                                trailing: selected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
                                onTap: () {
                                  picked = c;
                                  // update the parent form's selected category and close dialog
                                  setState(() {
                                    _selectedCategory = picked;
                                  });
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                  ),

                  // Optional Close button row - white in dark mode
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : theme.textTheme.bodyLarge?.color,
                        ),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // prefix icon background and icon color for the standalone category tile
    final categoryPrefixBg = isDark ? Colors.white12 : Colors.black.withOpacity(0.06);
    final categoryIconColor = isDark ? Colors.white : Colors.black87;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title field: hintText (inside the field)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.text,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              decoration: _fieldDecoration(
                context: context,
                prefix: const Icon(Icons.note),
                hint: 'Title',
              ),
            ),
          ),

          // Full-width "dropdown" that opens the searchable dialog (prevents overlay overlap)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: GestureDetector(
              onTap: _openCategoryPicker,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: categoryPrefixBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(Icons.category, color: categoryIconColor, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCategory ?? 'Select category',
                        style: theme.textTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.keyboard_arrow_down, color: theme.textTheme.bodyLarge?.color),
                  ],
                ),
              ),
            ),
          ),

          // Amount field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter amount';
                final parsed = double.tryParse(v.replaceAll(',', ''));
                if (parsed == null) return 'Invalid number';
                if (parsed == 0) return 'Amount must be non-zero';
                return null;
              },
              decoration: _fieldDecoration(
                context: context,
                prefix: const Icon(Icons.attach_money),
                hint: 'Amount',
              ),
            ),
          ),

          // Income / Expense toggle and submit
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ToggleButtons(
                    isSelected: [_isIncome, !_isIncome],
                    onPressed: (index) {
                      setState(() {
                        _isIncome = index == 0;
                        // update available categories when switching type:
                        _selectedCategory = _currentCategories.isNotEmpty ? _currentCategories.first : null;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: theme.colorScheme.secondary,
                    color: theme.textTheme.bodyLarge?.color,
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text('Income')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text('Expense')),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}