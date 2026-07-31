import 'package:equatable/equatable.dart';

enum CategoryType { income, expense }

class Category extends Equatable {
  final int? id;
  final String name;
  final String icon;
  final String color;
  final CategoryType type;
  final bool isDefault;

  const Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
  });

  Category copyWith({int? id, String? name, String? icon, String? color, CategoryType? type, bool? isDefault}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, color, type, isDefault];
}