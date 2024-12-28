import 'dart:ui';

class SpinnerStyle {
  final String id;
  final String name;
  final List<Color> colors;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;

  const SpinnerStyle({
    required this.id,
    required this.name,
    required this.colors,
    required this.textColor,
    required this.fontSize,
    required this.fontWeight,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colors': colors.map((c) => c.value).toList(),
      'textColor': textColor.value,
      'fontSize': fontSize,
      'fontWeight': fontWeight.index,
    };
  }

  factory SpinnerStyle.fromJson(Map<String, dynamic> json) {
    return SpinnerStyle(
      id: json['id'] as String,
      name: json['name'] as String,
      colors: (json['colors'] as List).map((c) => Color(c as int)).toList(),
      textColor: Color(json['textColor'] as int),
      fontSize: json['fontSize'] as double,
      fontWeight: FontWeight.values[json['fontWeight'] as int],
    );
  }
}
