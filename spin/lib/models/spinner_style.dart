import 'dart:ui';

class SpinnerStyle {
  final String id;
  final String name;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;

  const SpinnerStyle({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.textColor,
    required this.fontSize,
    required this.fontWeight,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'backgroundColor': backgroundColor.value,
      'borderColor': borderColor.value,
      'borderWidth': borderWidth,
      'textColor': textColor.value,
      'fontSize': fontSize,
      'fontWeight': fontWeight.index,
    };
  }

  factory SpinnerStyle.fromJson(Map<String, dynamic> json) {
    return SpinnerStyle(
      id: json['id'] as String,
      name: json['name'] as String,
      backgroundColor: Color(json['backgroundColor'] as int),
      borderColor: Color(json['borderColor'] as int),
      borderWidth: json['borderWidth'] as double,
      textColor: Color(json['textColor'] as int),
      fontSize: json['fontSize'] as double,
      fontWeight: FontWeight.values[json['fontWeight'] as int],
    );
  }
}
