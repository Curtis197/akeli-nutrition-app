class AllergenModel {
  final String id;
  final String slug;
  final String label;

  const AllergenModel({
    required this.id,
    required this.slug,
    required this.label,
  });

  factory AllergenModel.fromJson(Map<String, dynamic> json) {
    return AllergenModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      label: json['label'] as String,
    );
  }
}
