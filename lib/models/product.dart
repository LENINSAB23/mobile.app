class ProductModel {
  final int id;
  final int categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final int prepTimeMinutes;

  ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.prepTimeMinutes,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: json['image_url'],
      prepTimeMinutes: json['prep_time_minutes'] ?? 15,
    );
  }
}
