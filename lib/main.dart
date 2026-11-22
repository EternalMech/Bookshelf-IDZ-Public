import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'data/book_store.dart';
import 'data/demo_session_store.dart';
import 'screens/bookshelf_screen.dart';
import 'screens/demo_sign_in_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    BookshelfApp(
      store: PreferencesBookStore(),
      sessionStore: PreferencesDemoSessionStore(),
    ),
  );
}

class BookshelfApp extends StatefulWidget {
  const BookshelfApp({
    super.key,
    required this.store,
    required this.sessionStore,
  });
  final BookStore store;
  final DemoSessionStore sessionStore;

  @override
  State<BookshelfApp> createState() => _BookshelfAppState();
}

class _BookshelfAppState extends State<BookshelfApp> {
  late final SemanticsHandle _semantics;
  late Future<bool> _storedSession;

  @override
  void initState() {
    super.initState();
    _semantics = SemanticsBinding.instance.ensureSemantics();
    _storedSession = widget.sessionStore.load();
  }

  @override
  void dispose() {
    _semantics.dispose();
    super.dispose();
  }

  Future<void> _setSignedIn(bool signedIn) async {
    await widget.sessionStore.save(signedIn);
    if (!mounted) return;
    setState(() {
      _storedSession = SynchronousFuture(signedIn);
    });
  }

  void _retrySessionLoad() {
    final session = widget.sessionStore.load();
    setState(() {
      _storedSession = session;
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Между строк — книжная полка',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8F7F3),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF34594A),
        primary: const Color(0xFF34594A),
        surface: const Color(0xFFF8F7F3),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.3,
          color: Color(0xFF273C33),
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF273C33),
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF273C33),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF273C33),
        ),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF68746C)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4E7E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4E7E0)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    ),
    home: FutureBuilder<bool>(
      future: _storedSession,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(semanticsLabel: 'Загрузка'),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Не удалось проверить вход. Проверьте, что браузер '
                      'разрешает локальное хранение.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _retrySessionLoad,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (snapshot.data == true) {
          return BookshelfScreen(
            store: widget.store,
            onSignOut: () => _setSignedIn(false),
          );
        }
        return DemoSignInScreen(onSignIn: () => _setSignedIn(true));
      },
    ),
  );
}
