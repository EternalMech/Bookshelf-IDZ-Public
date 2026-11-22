import 'package:flutter/foundation.dart';
import 'data/book_store.dart';
import 'models/book.dart';

class BookshelfController extends ChangeNotifier {
  BookshelfController(this.store);
  final BookStore store;
  List<Book> _books = [];
  bool loading = true;
  bool saving = false;
  bool loadFailed = false;
  bool _disposed = false;
  ReadingStatus? filter;
  String search = '';
  List<Book> get books => List.unmodifiable(_books);
  List<Book> get visibleBooks {
    final query = search.trim().toLowerCase();
    return _books
        .where(
          (book) =>
              (filter == null || book.status == filter) &&
              (query.isEmpty ||
                  '${book.title} ${book.author}'.toLowerCase().contains(query)),
        )
        .toList();
  }

  int count(ReadingStatus status) =>
      _books.where((book) => book.status == status).length;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    loading = true;
    loadFailed = false;
    _notify();
    try {
      final saved = await store.load();
      final initial = saved ?? exampleBooks();
      if (saved == null) await store.save(initial);
      _books = initial;
    } catch (_) {
      loadFailed = true;
    } finally {
      loading = false;
      _notify();
    }
  }

  void setFilter(ReadingStatus? value) {
    filter = value;
    _notify();
  }

  void setSearch(String value) {
    search = value;
    _notify();
  }

  void clearFilters() {
    filter = null;
    search = '';
    _notify();
  }

  Future<bool> addBook(String title, String author) async {
    if (title.trim().isEmpty || author.trim().isEmpty) return false;
    final book = Book(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      author: author.trim(),
      status: ReadingStatus.planned,
      createdAt: DateTime.now(),
      palette: _books.length % 6,
    );
    final success = await _commit([book, ..._books]);
    if (success) clearFilters();
    return success;
  }

  Future<bool> changeStatus(Book book, ReadingStatus status) => _commit(
    _books
        .map((item) => item.id == book.id ? item.withStatus(status) : item)
        .toList(),
  );
  Future<bool> deleteBook(Book book) =>
      _commit(_books.where((item) => item.id != book.id).toList());
  Future<bool> _commit(List<Book> next) async {
    if (saving || loading || loadFailed) return false;
    saving = true;
    _notify();
    try {
      await store.save(next);
      _books = next;
      return true;
    } catch (_) {
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
