import 'spinner_item.dart';
import 'spinner_style.dart';
import 'package:flutter/material.dart';

class Spinner {
  final String id;
  final String name;
  final List<SpinnerItem> items;
  final SpinnerStyle style;
  final bool showPercentages;
  final bool dynamicWeightScaling;
  final double selectedPenalty;

  const Spinner({
    required this.id,
    required this.name,
    required this.items,
    required this.style,
    this.showPercentages = false,
    this.dynamicWeightScaling = false,
    this.selectedPenalty = 100.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
      'style': style.toJson(),
      'showPercentages': showPercentages,
      'dynamicWeightScaling': dynamicWeightScaling,
      'selectedPenalty': selectedPenalty,
    };
  }

  factory Spinner.fromJson(Map<String, dynamic> json) {
    // Default style for migration from old data
    final defaultStyle = SpinnerStyle(
      id: 'rainbow',
      name: 'Rainbow',
      colors: [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.indigo,
        Colors.purple,
      ],
      textColor: Colors.white,
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
      showPercentages: json['showPercentages'] as bool? ?? false,
      dynamicWeightScaling: json['dynamicWeightScaling'] as bool? ?? false,
      selectedPenalty: json['selectedPenalty'] as double? ?? 100.0,
    );
  }

  Spinner copyWith({
    String? id,
    String? name,
    List<SpinnerItem>? items,
    SpinnerStyle? style,
    bool? showPercentages,
    bool? dynamicWeightScaling,
    double? selectedPenalty,
  }) {
    return Spinner(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      style: style ?? this.style,
      showPercentages: showPercentages ?? this.showPercentages,
      dynamicWeightScaling: dynamicWeightScaling ?? this.dynamicWeightScaling,
      selectedPenalty: selectedPenalty ?? this.selectedPenalty,
    );
  }

  double get maxWeight => items.length * 100.0;
}
