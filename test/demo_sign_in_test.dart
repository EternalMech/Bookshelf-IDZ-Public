import 'package:bookshelf_idz/main.dart';
import 'package:bookshelf_idz/models/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Finder get login => find.widgetWithText(TextFormField, 'Логин');
Finder get password => find.widgetWithText(TextFormField, 'Пароль');

Future<void> enterDemoCredentials(WidgetTester tester) async {
  await tester.enterText(login, 'demo');
  await tester.enterText(password, 'bookshelf');
}

void main() {
  testWidgets('demo sign-in validates both fields before storing a session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final books = MemoryBookStore();
    final session = MemoryDemoSessionStore();
    await tester.pumpWidget(BookshelfApp(store: books, sessionStore: session));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(RegExp('для демо', caseSensitive: false)),
      findsNothing,
    );
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: password, matching: find.byType(TextField)),
          )
          .obscureText,
      isTrue,
    );
    await tester.ensureVisible(find.text('Войти'));
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.text('Введите логин'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);

    for (final (name, pass) in [('other', 'bookshelf'), ('demo', 'wrong')]) {
      await tester.enterText(login, name);
      await tester.enterText(password, pass);
      await tester.ensureVisible(find.text('Войти'));
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('Неверный логин или пароль'), findsOneWidget);
      expect(session.writes, 0);
      expect(books.writes, 0);
    }

    await enterDemoCredentials(tester);
    await tester.ensureVisible(find.text('Войти'));
    await tester.tap(find.text('Войти'));
    await tester.pump();
    expect(find.text('Входим…'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(session.writes, 0);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Моя книжная полка'), findsOneWidget);
    expect(session.signedIn, isTrue);
    expect(session.writes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restores the session and keeps books when signing out', (
    tester,
  ) async {
    final book = exampleBooks().first.withStatus(ReadingStatus.finished);
    final books = MemoryBookStore([book]);
    final session = MemoryDemoSessionStore(signedIn: true);

    Future<void> openApp() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        BookshelfApp(store: books, sessionStore: session),
      );
      await tester.pumpAndSettle();
    }

    await openApp();
    expect(find.text('Моя книжная полка'), findsOneWidget);
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();
    expect(find.text('Войти'), findsOneWidget);
    expect(session.signedIn, isFalse);
    expect(books.value!.single.status, ReadingStatus.finished);
    expect(books.writes, 0);

    await openApp();
    expect(find.text('Войти'), findsOneWidget);
    await enterDemoCredentials(tester);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await openApp();
    expect(find.text('Моя книжная полка'), findsOneWidget);
    expect(books.value!.single.status, ReadingStatus.finished);
    expect(books.writes, 0);
  });

  testWidgets('recovers from a session read or write failure', (tester) async {
    final session = MemoryDemoSessionStore()
      ..failLoad = true
      ..failSave = true;
    await tester.pumpWidget(
      BookshelfApp(store: MemoryBookStore([]), sessionStore: session),
    );
    await tester.pumpAndSettle();
    expect(find.text('Повторить'), findsOneWidget);
    session.failLoad = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    await enterDemoCredentials(tester);
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.textContaining('Не удалось сохранить вход'), findsOneWidget);
    expect(find.text('Моя книжная полка'), findsNothing);

    session.failSave = false;
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Моя книжная полка'), findsOneWidget);

    session.failSave = true;
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();
    expect(find.text('Моя книжная полка'), findsOneWidget);
    expect(find.textContaining('Не удалось выйти'), findsOneWidget);
    expect(session.signedIn, isTrue);
  });
}
