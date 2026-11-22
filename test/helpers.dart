import 'package:bookshelf_idz/data/book_store.dart';
import 'package:bookshelf_idz/data/demo_session_store.dart';
import 'package:bookshelf_idz/models/book.dart';

class MemoryBookStore implements BookStore {
  MemoryBookStore([this.value]);
  List<Book>? value;
  bool failSave = false;
  bool failLoad = false;
  int writes = 0;
  @override
  Future<List<Book>?> load() async {
    if (failLoad) throw const FormatException('Invalid stored data');
    return value == null ? null : List.of(value!);
  }

  @override
  Future<void> save(List<Book> books) async {
    if (failSave) throw StateError('Storage unavailable');
    value = List.of(books);
    writes++;
  }
}

class MemoryDemoSessionStore implements DemoSessionStore {
  MemoryDemoSessionStore({this.signedIn = false});

  bool signedIn;
  bool failLoad = false;
  bool failSave = false;
  int writes = 0;

  @override
  Future<bool> load() async {
    if (failLoad) throw StateError('Storage unavailable');
    return signedIn;
  }

  @override
  Future<void> save(bool signedIn) async {
    if (failSave) throw StateError('Storage unavailable');
    this.signedIn = signedIn;
    writes++;
  }
}
