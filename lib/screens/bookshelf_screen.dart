import 'package:flutter/material.dart';

import '../bookshelf_controller.dart';
import '../data/book_store.dart';
import '../models/book.dart';

const ink = Color(0xFF273C33);
const green = Color(0xFF34594A);
const muted = Color(0xFF788179);
const line = Color(0xFFE4E7E0);

class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({
    super.key,
    required this.store,
    required this.onSignOut,
  });
  final BookStore store;
  final Future<void> Function() onSignOut;
  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  late final BookshelfController controller;
  final search = TextEditingController();
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    controller = BookshelfController(widget.store)..initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    search.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    if (_signingOut || controller.saving) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    setState(() => _signingOut = true);
    try {
      await widget.onSignOut();
    } catch (_) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось выйти. Попробуйте ещё раз.')),
      );
    }
  }

  Future<void> addBook() async {
    final added = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddBookDialog(onSave: controller.addBook),
    );
    if (!mounted || added != true) return;
    search.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Книга добавлена на полку')));
  }

  Future<void> changeStatus(Book book, ReadingStatus status) async {
    final ok = await controller.changeStatus(book, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '«${book.title}»: ${status.label.toLowerCase()}'
              : 'Не удалось сохранить. Изменения не применены. Попробуйте ещё раз.',
        ),
      ),
    );
  }

  Future<void> deleteBook(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Убрать книгу с полки?'),
        content: Text('«${book.title}» будет удалена из вашего списка.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Оставить'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await controller.deleteBook(book);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Книга удалена'
              : 'Не удалось удалить книгу. Попробуйте ещё раз.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide) _sidebar(compact: constraints.maxHeight < 760),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Padding(
                          padding: EdgeInsets.all(
                            constraints.maxWidth < 600 ? 20 : 36,
                          ),
                          child: _content(context, wide),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _sidebar({required bool compact}) => Container(
    width: 220,
    padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
    decoration: const BoxDecoration(
      color: Color(0xFFF1F2EB),
      border: Border(right: BorderSide(color: line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Brand(),
        const SizedBox(height: 52),
        const Text(
          'БИБЛИОТЕКА',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: muted,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 14),
        _nav(null, Icons.grid_view_rounded, 'Вся полка'),
        _nav(
          ReadingStatus.planned,
          Icons.bookmark_border_rounded,
          'Хочу прочитать',
        ),
        _nav(ReadingStatus.reading, Icons.menu_book_rounded, 'Читаю сейчас'),
        _nav(ReadingStatus.finished, Icons.task_alt_rounded, 'Прочитано'),
        const Spacer(),
        if (!compact)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E9DE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: green, size: 21),
                SizedBox(height: 10),
                Text(
                  'По одной странице',
                  style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'Большие истории начинаются с маленькой привычки.',
                  style: TextStyle(fontSize: 12, color: muted, height: 1.6),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        const Text(
          'Личная полка · учебный прототип',
          style: TextStyle(fontSize: 10, color: muted),
        ),
      ],
    ),
  );

  Widget _nav(ReadingStatus? status, IconData icon, String label) {
    final selected = controller.filter == status;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: selected ? green : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => controller.setFilter(status),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 18, color: selected ? Colors.white : muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : ink,
                    ),
                  ),
                ),
                Text(
                  '${status == null ? controller.books.length : controller.count(status)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white70 : muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, bool wide) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: !wide
                ? const _Brand()
                : const Text(
                    'ЛИЧНАЯ БИБЛИОТЕКА',
                    style: TextStyle(
                      fontSize: 10,
                      color: muted,
                      letterSpacing: 2,
                    ),
                  ),
          ),
          if (wide || controller.saving) ...[
            Text(
              controller.saving ? 'Сохраняем…' : 'На этом устройстве',
              style: const TextStyle(fontSize: 11, color: muted),
            ),
            const SizedBox(width: 12),
          ],
          TextButton.icon(
            onPressed: _signingOut || controller.saving ? null : _signOut,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(_signingOut ? 'Выходим…' : 'Выйти'),
          ),
        ],
      ),
      const SizedBox(height: 24),
      _booksContent(context),
    ],
  );

  Widget _booksContent(BuildContext context) {
    if (controller.loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 160),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.loadFailed) {
      return Padding(
        padding: const EdgeInsets.only(top: 120),
        child: _EmptyState(
          title: 'Не удалось открыть полку',
          description:
              'Хранилище недоступно или данные повреждены. Мы не будем их перезаписывать.',
          icon: Icons.cloud_off_rounded,
          action: 'Повторить',
          onAction: controller.initialize,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Моя книжная полка',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        const Text(
          'Сохраняйте истории, к которым хочется вернуться.',
          style: TextStyle(color: muted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Всего книг',
                value: controller.books.length,
                icon: Icons.auto_stories_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                label: 'Сейчас читаю',
                value: controller.count(ReadingStatus.reading),
                icon: Icons.menu_book_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                label: 'Прочитано',
                value: controller.count(ReadingStatus.finished),
                icon: Icons.task_alt_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            final field = TextField(
              controller: search,
              onChanged: controller.setSearch,
              decoration: InputDecoration(
                hintText: 'Название книги или автор',
                prefixIcon: const Icon(Icons.search_rounded, size: 21),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Очистить поиск',
                        onPressed: () {
                          search.clear();
                          controller.setSearch('');
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
              ),
            );
            final button = FilledButton.icon(
              onPressed: controller.saving ? null : addBook,
              icon: const Icon(Icons.add, size: 19),
              label: const Text('Добавить книгу'),
            );
            if (constraints.maxWidth < 570) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [field, const SizedBox(height: 12), button],
              );
            }
            return Row(
              children: [
                Expanded(child: field),
                const SizedBox(width: 16),
                button,
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip(null, 'Все книги', controller.books.length),
            ...ReadingStatus.values.map(
              (status) =>
                  _filterChip(status, status.label, controller.count(status)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (controller.visibleBooks.isEmpty)
          _EmptyState(
            title: controller.books.isEmpty
                ? 'Ваша история начинается здесь'
                : 'Книги не найдены',
            description: controller.books.isEmpty
                ? 'Добавьте первую книгу — и сохраните место для новых историй.'
                : 'Попробуйте другой запрос или выберите все книги.',
            icon: Icons.auto_stories_outlined,
            action: controller.books.isEmpty
                ? 'Добавить первую книгу'
                : 'Сбросить фильтры',
            onAction: () {
              if (controller.books.isEmpty) {
                addBook();
              } else {
                search.clear();
                controller.clearFilters();
              }
            },
          )
        else
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth >= 820
                    ? 3
                    : constraints.maxWidth >= 530
                    ? 2
                    : 1,
                mainAxisExtent: 360,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: controller.visibleBooks.length,
              itemBuilder: (context, i) {
                final book = controller.visibleBooks[i];
                return _BookCard(
                  book: book,
                  busy: controller.saving,
                  onStatus: (status) => changeStatus(book, status),
                  onDelete: () => deleteBook(book),
                );
              },
            ),
          ),
        const SizedBox(height: 26),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, color: muted, size: 13),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Полка сохранится в этом браузере даже после выхода.',
                style: TextStyle(fontSize: 11, color: muted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _filterChip(ReadingStatus? status, String label, int count) =>
      ChoiceChip(
        selected: controller.filter == status,
        onSelected: (_) => controller.setFilter(status),
        showCheckmark: false,
        label: Text('$label  $count'),
        labelStyle: TextStyle(
          fontSize: 12,
          color: controller.filter == status ? Colors.white : muted,
        ),
        selectedColor: green,
        backgroundColor: Colors.transparent,
        side: BorderSide(color: controller.filter == status ? green : line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      );
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.auto_stories_rounded, color: green, size: 25),
      SizedBox(width: 10),
      Flexible(
        child: Text(
          'между строк',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -.6,
          ),
        ),
      ),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: muted),
            const Spacer(),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 2,
          style: const TextStyle(fontSize: 11, color: muted),
        ),
      ],
    ),
  );
}

const _palettes = [
  (Color(0xFFE7E9C9), Color(0xFF485B34)),
  (Color(0xFFE4CCB1), Color(0xFF6B4938)),
  (Color(0xFFD8E1DC), Color(0xFF34594A)),
  (Color(0xFFDCD7EB), Color(0xFF615678)),
  (Color(0xFFF0D9CD), Color(0xFF915C4B)),
  (Color(0xFFEBDFAF), Color(0xFF76632F)),
];

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.busy,
    required this.onStatus,
    required this.onDelete,
  });
  final Book book;
  final bool busy;
  final ValueChanged<ReadingStatus> onStatus;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final palette = _palettes[book.palette.abs() % _palettes.length];
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              height: 170,
              width: double.infinity,
              color: palette.$1,
              child: Stack(
                children: [
                  Positioned(
                    right: -22,
                    bottom: -55,
                    child: Container(
                      width: 175,
                      height: 175,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: palette.$2.withValues(alpha: .13),
                          width: 27,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: palette.$2.withValues(alpha: .15),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 20, 22, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'МЕЖДУ СТРОК',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.1,
                            color: palette.$2,
                          ),
                        ),
                        const SizedBox(height: 13),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              book.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                color: palette.$2,
                                height: 1.08,
                                letterSpacing: -.7,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.author.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8,
                            letterSpacing: 1.3,
                            color: palette.$2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 15, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: book.status == ReadingStatus.reading
                              ? const Color(0xFFFFF1D5)
                              : const Color(0xFFEDF1E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          book.status.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: book.status == ReadingStatus.reading
                                ? const Color(0xFF946922)
                                : green,
                          ),
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        tooltip: 'Действия: ${book.title}',
                        enabled: !busy,
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          size: 19,
                          color: muted,
                        ),
                        onSelected: (value) {
                          if (value == 'delete') {
                            onDelete();
                          } else {
                            onStatus(ReadingStatus.values.byName(value));
                          }
                        },
                        itemBuilder: (_) => [
                          ...ReadingStatus.values.map(
                            (status) => PopupMenuItem(
                              value: status.name,
                              child: Text(status.label),
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Удалить книгу'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: busy || book.status == ReadingStatus.finished
                        ? null
                        : () => onStatus(
                            book.status == ReadingStatus.planned
                                ? ReadingStatus.reading
                                : ReadingStatus.finished,
                          ),
                    icon: Icon(
                      book.status == ReadingStatus.finished
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 15,
                    ),
                    label: Text(switch (book.status) {
                      ReadingStatus.planned => 'Начать читать',
                      ReadingStatus.reading => 'Отметить прочитанной',
                      ReadingStatus.finished => 'Прочитано',
                    }, style: const TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.description,
    required this.icon,
    required this.action,
    required this.onAction,
  });
  final String title;
  final String description;
  final IconData icon;
  final String action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 52, color: green),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, height: 1.5),
          ),
          const SizedBox(height: 18),
          OutlinedButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    ),
  );
}

class _AddBookDialog extends StatefulWidget {
  const _AddBookDialog({required this.onSave});
  final Future<bool> Function(String, String) onSave;
  @override
  State<_AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<_AddBookDialog> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final author = TextEditingController();
  bool saving = false;
  String? error;
  @override
  void dispose() {
    title.dispose();
    author.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.onSave(title.text, author.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        saving = false;
        error = 'Не удалось сохранить книгу. Попробуйте ещё раз.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      title: const Text('Новая история на полке'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Добавьте книгу, которую хотите прочитать.'),
              const SizedBox(height: 24),
              TextFormField(
                controller: title,
                autofocus: true,
                enabled: !saving,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Название книги',
                  hintText: 'Например, Маленький принц',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Введите название книги'
                    : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: author,
                enabled: !saving,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Автор',
                  hintText: 'Имя и фамилия автора',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Введите автора'
                    : null,
                onFieldSubmitted: (_) => submit(),
              ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: saving ? null : submit,
          child: Text(saving ? 'Сохраняем…' : 'На полку'),
        ),
      ],
    ),
  );
}
