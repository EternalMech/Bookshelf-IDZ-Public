import 'package:flutter/material.dart';

class DemoSignInScreen extends StatefulWidget {
  const DemoSignInScreen({super.key, required this.onSignIn});

  final Future<void> Function() onSignIn;

  @override
  State<DemoSignInScreen> createState() => _DemoSignInScreenState();
}

class _DemoSignInScreenState extends State<DemoSignInScreen> {
  static const _demoLogin = 'demo';
  static const _demoPassword = 'bookshelf';
  final _form = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  void _clearError(String _) {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _submit() async {
    if (_submitting || !_form.currentState!.validate()) return;

    final matchesDemo =
        _login.text.trim() == _demoLogin && _password.text == _demoPassword;

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });

    // Simulate a sign-in request without sending any data outside the app.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    if (!matchesDemo) {
      setState(() {
        _submitting = false;
        _error = 'Неверный логин или пароль';
      });
      return;
    }
    try {
      await widget.onSignIn();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Не удалось сохранить вход в браузере. Попробуйте ещё раз.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE4E7E0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F2EB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.auto_stories_rounded,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Между строк',
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text('Войдите, чтобы открыть книжную полку.'),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _login,
                          enabled: !_submitting,
                          decoration: const InputDecoration(labelText: 'Логин'),
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.next,
                          autovalidateMode:
                              AutovalidateMode.onUserInteractionIfError,
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Введите логин'
                              : null,
                          onChanged: _clearError,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          enabled: !_submitting,
                          decoration: const InputDecoration(
                            labelText: 'Пароль',
                          ),
                          obscureText: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.done,
                          autovalidateMode:
                              AutovalidateMode.onUserInteractionIfError,
                          validator: (value) =>
                              (value ?? '').isEmpty ? 'Введите пароль' : null,
                          onChanged: _clearError,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _error!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _submitting ? null : _submit,
                          child: Text(_submitting ? 'Входим…' : 'Войти'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
