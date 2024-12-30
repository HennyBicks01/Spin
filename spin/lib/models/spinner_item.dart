class SpinnerItem {
  final String id;
  final String title;
  final String description;
  final bool enabled;
  final double weight; // Stored as decimal (1.0 = 100%)

  const SpinnerItem({
    required this.id,
    required this.title,
    required this.description,
    this.enabled = true,
    this.weight = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'enabled': enabled,
      'weight': weight,
    };
  }

  factory SpinnerItem.fromJson(Map<String, dynamic> json) {
    return SpinnerItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      enabled: json['enabled'] as bool? ?? true,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  SpinnerItem copyWith({
    String? id,
    String? title,
    String? description,
    bool? enabled,
    double? weight,
  }) {
    return SpinnerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      weight: weight ?? this.weight,
    );
  }
}
