class CategoryModel {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? imageUrl;
  final int? parentId;

  const CategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.imageUrl,
    this.parentId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
      imageUrl: json['image_url'],
      parentId: json['parent_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'image_url': imageUrl,
      'parent_id': parentId,
    };
  }
}