class SpinnerItem {
  final String id;
  final String title;
  final String description;

  const SpinnerItem({
    required this.id,
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }

  factory SpinnerItem.fromJson(Map<String, dynamic> json) {
    return SpinnerItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }
}
