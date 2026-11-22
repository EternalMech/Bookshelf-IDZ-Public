import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

abstract interface class BookStore {
  Future<List<Book>?> load();
  Future<void> save(List<Book> books);
}

class PreferencesBookStore implements BookStore {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static const storageKey = 'between_lines.books.v1';
  @override
  Future<List<Book>?> load() async {
    final raw = await _preferences.getString(storageKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    if (decoded['version'] != 1) {
      throw const FormatException('Unsupported data version');
    }
    return (decoded['books'] as List<dynamic>)
        .map((item) => Book.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> save(List<Book> books) => _preferences.setString(
    storageKey,
    jsonEncode({
      'version': 1,
      'books': books.map((book) => book.toJson()).toList(),
    }),
  );
}
