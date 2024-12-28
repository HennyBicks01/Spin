import 'spinner_item.dart';

class Spinner {
  final String id;
  final String name;
  final List<SpinnerItem> items;

  const Spinner({
    required this.id,
    required this.name,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory Spinner.fromJson(Map<String, dynamic> json) {
    return Spinner(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List)
          .map((item) => SpinnerItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
