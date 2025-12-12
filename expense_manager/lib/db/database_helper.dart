import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:expense_manager/models/transaction_item.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static const _dbName = 'expense_manager.db';
  static const _dbVersion = 1;
  static const tableTransactions = 'transactions';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Database? _database;

  Future<void> initDB() async {
    if (_database != null) return;
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        isIncome INTEGER NOT NULL,
        category TEXT NOT NULL
      )
    ''');
    // Insert sample data
    // final now = DateTime.now().millisecondsSinceEpoch;
    // await db.insert(tableTransactions, {
    //   'id': 't1',
    //   'title': 'Salary',
    //   'amount': 3200.0,
    //   'date': now - (2 * 86400000),
    //   'isIncome': 1,
    //   'category': 'Job',
    // });
    // await db.insert(tableTransactions, {
    //   'id': 't2',
    //   'title': 'Groceries',
    //   'amount': 76.45,
    //   'date': now - (1 * 86400000),
    //   'isIncome': 0,
    //   'category': 'Food',
    // });
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initDB();
    return _database!;
  }

  Future<List<TransactionItem>> getAllTransactions() async {
    final db = await database;
    final res = await db.query(tableTransactions, orderBy: 'date DESC');
    return res.map((e) => TransactionItem.fromMap(e)).toList();
  }

  Future<int> insertTransaction(TransactionItem item) async {
    final db = await database;
    return db.insert(tableTransactions, item.toMap());
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return db.delete(tableTransactions, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateTransaction(TransactionItem item) async {
    final db = await database;
    return db.update(tableTransactions, item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }
}