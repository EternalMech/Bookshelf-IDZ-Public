enum ReadingStatus {
  planned('Хочу прочитать'),
  reading('Читаю'),
  finished('Прочитано');

  const ReadingStatus(this.label);
  final String label;
}

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.status,
    required this.createdAt,
    this.palette = 0,
  });
  final String id;
  final String title;
  final String author;
  final ReadingStatus status;
  final DateTime createdAt;
  final int palette;

  Book withStatus(ReadingStatus value) => Book(
    id: id,
    title: title,
    author: author,
    status: value,
    createdAt: createdAt,
    palette: palette,
  );
  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'palette': palette,
  };
  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'] as String,
    title: json['title'] as String,
    author: json['author'] as String,
    status: ReadingStatus.values.byName(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    palette: json['palette'] as int? ?? 0,
  );
}

List<Book> exampleBooks() {
  const items = [
    ('Маленький принц', 'Антуан де Сент-Экзюпери', ReadingStatus.reading),
    ('Атомные привычки', 'Джеймс Клир', ReadingStatus.planned),
    ('Тревожные люди', 'Фредрик Бакман', ReadingStatus.planned),
    ('Цветы для Элджернона', 'Дэниел Киз', ReadingStatus.finished),
    ('К себе нежно', 'Ольга Примаченко', ReadingStatus.reading),
    ('Вино из одуванчиков', 'Рэй Брэдбери', ReadingStatus.finished),
  ];
  return List.generate(
    items.length,
    (i) => Book(
      id: 'example-$i',
      title: items[i].$1,
      author: items[i].$2,
      status: items[i].$3,
      createdAt: DateTime(2026, 11, 11).subtract(Duration(minutes: i)),
      palette: i,
    ),
  );
}
