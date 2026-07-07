class MenuCategory {
  const MenuCategory({required this.id, required this.name, required this.items});

  final int id;
  final String name;
  final List<MenuItem> items;

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
        id: json['id'] as int,
        name: json['name'] as String,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.sellPrice,
    this.description,
  });

  final int id;
  final String name;
  final double sellPrice;
  final String? description;

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'] as int,
        name: json['name'] as String,
        sellPrice: double.parse(json['sell_price'].toString()),
        description: json['description'] as String?,
      );
}
