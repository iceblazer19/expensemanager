import 'package:flutter/foundation.dart';
import 'package:expense_manager/models/transaction_item.dart';
import 'package:expense_manager/db/database_helper.dart';
import 'dart:math';

class TransactionProvider extends ChangeNotifier {
  List<TransactionItem> _items = [];
  List<TransactionItem> get items => List.unmodifiable(_items);

  Future<void> loadTransactions() async {
    _items = await DatabaseHelper.instance.getAllTransactions();
    notifyListeners();
  }

  Future<void> addTransaction(TransactionItem item) async {
    await DatabaseHelper.instance.insertTransaction(item);
    _items.insert(0, item);
    notifyListeners();
  }

  Future<void> removeTransaction(String id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    _items.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  double get totalIncome =>
      _items.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

  double get totalExpense =>
      _items.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

  double get balance => totalIncome - totalExpense;

  String generateId() {
    return 't${Random().nextInt(1000000)}';
  }
}