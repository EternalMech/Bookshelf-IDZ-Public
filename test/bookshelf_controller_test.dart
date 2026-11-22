import 'package:bookshelf_idz/bookshelf_controller.dart';
import 'package:bookshelf_idz/models/book.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('book JSON round trip preserves fields', () {
    final book = exampleBooks().first;
    expect(Book.fromJson(book.toJson()).toJson(), book.toJson());
  });

  test('first launch seeds examples only once', () async {
    final store = MemoryBookStore();
    final controller = BookshelfController(store);
    await controller.initialize();
    expect(controller.books.length, 6);
    expect(store.writes, 1);
    await controller.initialize();
    expect(store.writes, 1);
    controller.dispose();
  });

  test('persisted empty list stays empty after reload', () async {
    final controller = BookshelfController(MemoryBookStore([]));
    await controller.initialize();
    expect(controller.books, isEmpty);
    controller.dispose();
  });

  test(
    'add trims input, clears filters and survives a new controller',
    () async {
      final store = MemoryBookStore([]);
      final controller = BookshelfController(store);
      await controller.initialize();
      controller.setFilter(ReadingStatus.finished);
      controller.setSearch('not found');
      expect(await controller.addBook('  Дюна  ', ' Фрэнк Герберт '), isTrue);
      expect(controller.visibleBooks.single.title, 'Дюна');
      expect(controller.visibleBooks.single.author, 'Фрэнк Герберт');
      expect(controller.filter, isNull);
      final reloaded = BookshelfController(store);
      await reloaded.initialize();
      expect(reloaded.books.single.title, 'Дюна');
      controller.dispose();
      reloaded.dispose();
    },
  );

  test('empty title and author are rejected', () async {
    final store = MemoryBookStore([]);
    final controller = BookshelfController(store);
    await controller.initialize();
    expect(await controller.addBook(' ', 'Автор'), isFalse);
    expect(await controller.addBook('Книга', ''), isFalse);
    expect(store.writes, 0);
    controller.dispose();
  });

  test('status change and deletion persist', () async {
    final store = MemoryBookStore([exampleBooks().first]);
    final controller = BookshelfController(store);
    await controller.initialize();
    await controller.changeStatus(
      controller.books.single,
      ReadingStatus.finished,
    );
    expect(store.value!.single.status, ReadingStatus.finished);
    await controller.deleteBook(controller.books.single);
    await controller.initialize();
    expect(controller.books, isEmpty);
    controller.dispose();
  });

  test('search is case-insensitive and combines with status', () async {
    final controller = BookshelfController(MemoryBookStore(exampleBooks()));
    await controller.initialize();
    controller.setSearch('кЛиР');
    expect(controller.visibleBooks.single.title, 'Атомные привычки');
    controller.setFilter(ReadingStatus.finished);
    expect(controller.visibleBooks, isEmpty);
    controller.dispose();
  });

  test('write failure does not pretend changes were saved', () async {
    final store = MemoryBookStore([])..failSave = true;
    final controller = BookshelfController(store);
    await controller.initialize();
    expect(await controller.addBook('Книга', 'Автор'), isFalse);
    expect(controller.books, isEmpty);
    expect(controller.saving, isFalse);
    controller.dispose();
  });

  test('corrupt storage is not overwritten with demo data', () async {
    final store = MemoryBookStore()..failLoad = true;
    final controller = BookshelfController(store);
    await controller.initialize();
    expect(controller.loadFailed, isTrue);
    expect(store.writes, 0);
    controller.dispose();
  });
}
