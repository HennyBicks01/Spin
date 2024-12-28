import 'spinner_item.dart';
import 'spinner_style.dart';
import 'package:flutter/material.dart';

class Spinner {
  final String id;
  final String name;
  final List<SpinnerItem> items;
  final SpinnerStyle style;

  const Spinner({
    required this.id,
    required this.name,
    required this.items,
    required this.style,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
      'style': style.toJson(),
    };
  }

  factory Spinner.fromJson(Map<String, dynamic> json) {
    // Default style for migration from old data
    final defaultStyle = SpinnerStyle(
      id: 'default',
      name: 'Default',
      backgroundColor: Colors.blue.shade100,
      borderColor: Colors.blue,
      borderWidth: 2,
      textColor: Colors.black,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    return Spinner(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List)
          .map((item) => SpinnerItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      style: json['style'] != null 
          ? SpinnerStyle.fromJson(json['style'] as Map<String, dynamic>)
          : defaultStyle,
    );
  }
}
