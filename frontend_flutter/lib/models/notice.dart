class Notice {
  final int id;
  final int teacher;
  final String teacherName;
  final String title;
  final String content;
  final DateTime createdAt;

  Notice({
    required this.id,
    required this.teacher,
    required this.teacherName,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'],
      teacher: json['teacher'],
      teacherName: json['teacher_name'] ?? '',
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
    };
  }
}
