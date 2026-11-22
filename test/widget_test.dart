import 'package:bookshelf_idz/main.dart';
import 'package:bookshelf_idz/models/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers.dart';

void main() {
  testWidgets('short desktop window does not overflow the sidebar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BookshelfApp(
        store: MemoryBookStore(exampleBooks()),
        sessionStore: MemoryDemoSessionStore(signedIn: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('add form validates and creates a book', (tester) async {
    final store = MemoryBookStore([]);
    await tester.pumpWidget(
      BookshelfApp(
        store: store,
        sessionStore: MemoryDemoSessionStore(signedIn: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить книгу'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('На полку'));
    await tester.pumpAndSettle();
    expect(find.text('Введите название книги'), findsOneWidget);
    expect(find.text('Введите автора'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Дюна');
    await tester.enterText(find.byType(TextFormField).at(1), 'Фрэнк Герберт');
    await tester.tap(find.text('На полку'));
    await tester.pumpAndSettle();
    expect(find.text('Книга добавлена на полку'), findsOneWidget);
    expect(store.value!.single.title, 'Дюна');
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow screen and no-results state do not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BookshelfApp(
        store: MemoryBookStore(exampleBooks()),
        sessionStore: MemoryDemoSessionStore(signedIn: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Книги которой нет');
    await tester.pumpAndSettle();
    expect(find.text('Книги не найдены'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
