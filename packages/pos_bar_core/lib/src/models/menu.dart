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
    this.listPrice,
    this.promoLabel,
    this.onPromo = false,
    this.description,
  });

  final int id;
  final String name;
  /// Effective price charged (promo price when active).
  final double sellPrice;
  /// Original list price when on promo; otherwise same as sellPrice.
  final double? listPrice;
  final String? promoLabel;
  final bool onPromo;
  final String? description;

  bool get hasPromo => onPromo && listPrice != null && listPrice! > sellPrice;

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final sell = double.parse(json['sell_price'].toString());
    final list = json['list_price'] != null ? double.parse(json['list_price'].toString()) : null;
    return MenuItem(
      id: json['id'] as int,
      name: json['name'] as String,
      sellPrice: sell,
      listPrice: list,
      promoLabel: json['promo_label'] as String?,
      onPromo: json['on_promo'] == true || (list != null && list > sell),
      description: json['description'] as String?,
    );
  }

  @override
  bool operator ==(Object other) => other is MenuItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
